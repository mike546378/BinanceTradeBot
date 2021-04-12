import { Intent, Position, Toaster } from "@blueprintjs/core";
import React, { useEffect, useRef, useState } from "react";

import { connectToSocket, disconnectFromSocket, sessionConnectionDefaultState, socketCallbacks } from "src/actions/socket_actions/SocketActions";
import { PromiseState } from "src/model/Enums";
import { ISessionState, RequestState } from "src/model/Models";
import { MainTableContainer } from "../main_table/MainTableContainer";

import { handleMessage } from "src/actions/socket_actions/MessageHandler";
import { ErrorLoader, SpinningLoader } from "src/components/general_purpose/page_loaders/PageLoaders";

import "./base.css";



export const AppBase: React.FC = () => {
    const defaultSessionState: RequestState<ISessionState> = { ...sessionConnectionDefaultState, payload: { ...sessionConnectionDefaultState.payload } };
    const [sessionConnectionState, setSessionConnectionState] = useState(defaultSessionState);
    const sessionRef = useRef<RequestState<ISessionState>>();
    sessionRef.current = sessionConnectionState;

    useEffect(() => {
        if (sessionConnectionState.payload.socket) { sessionConnectionState.payload.socket.socket.disconnect(); }
        setSessionConnectionState({ ...defaultSessionState, loadingState: PromiseState.Pending });
        connectToSocket(
            sessionConnectionState.payload,
            {
                ...socketCallbacks,
                onMessage: (e, p, r) => { return handleMessage({ event: e, payload: p, sessionState: sessionRef.current, setSessionState: setSessionConnectionState }); },
                onError: () => { console.log("Error"); },
                // onJoin: (e) => { console.log(e); setSessionConnectionState(connectionState(sessionConnectionState.payload, e));}
            })
            .then((result: RequestState<ISessionState>) => {
                setSessionConnectionState(result);
                if (result.loadingState === PromiseState.Rejected) {
                    Toaster.create({ position: Position.BOTTOM_RIGHT }).show({
                        intent: Intent.DANGER,
                        message: result.loadingError.message || "An error ocurred, please try again",
                        timeout: 20000,
                    });
                }
            });
        return () => {
            disconnectFromSocket(sessionRef.current, setSessionConnectionState, { message: "Navigated away from socket" });
        };
    }, []);

    const [loadingMessage, setLoadingMessage] = useState("Connecting to socket...");
    window.onbeforeunload = () => {
        setLoadingMessage("Disconnecting...");
        setSessionConnectionState({
            ...sessionRef.current,
            loadingState: PromiseState.Pending,
            loadingError: undefined,
        });
        disconnectFromSocket(sessionRef.current, setSessionConnectionState, { pending: true });
    };

    if (sessionConnectionState.loadingState === PromiseState.Pending || sessionConnectionState.loadingState === PromiseState.Default) return <SpinningLoader><h1>{loadingMessage}</h1></SpinningLoader>;
    if (sessionConnectionState.loadingState === PromiseState.Rejected) return <ErrorLoader message={sessionConnectionState.loadingError.message ? sessionConnectionState.loadingError.message : "An error occurred, please try again"} />;
    //return (<></>);
    return (<MainTableContainer {...sessionConnectionState.payload} />);
};

export default AppBase;