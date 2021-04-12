import { PromiseState } from "src/model/Enums";
import { ISessionState, RequestState } from "src/model/Models";

export interface IHandleMessageProps {
    event: string;
    payload: any;
    sessionState: RequestState<ISessionState>;
    setSessionState: React.Dispatch<React.SetStateAction<RequestState<ISessionState>>>;
}
export const handleMessage = (props: IHandleMessageProps) => {
    if (!props.payload || props.payload.status === "error")
        handleError({ ...props });
    switch (props.event) {
        case "end_session": {
            endSession(props);
            break;
        }
        case "connected": {
            sessionState(props);
            break;
        }
        default: {
            console.log({ messageHandler: "Default Message", data: {event: props.event, payload: {...props.payload}} });
        }
    }
    return props.payload;
};

export const handleError = (props: IHandleMessageProps) => {
    console.log("Error");
    props.setSessionState({
        ...props.sessionState,
        loadingState: PromiseState.Rejected,
        loadingError: { message: (props.payload.response.message ? props.payload.response.message : "An error occurred") },
    });
    props.sessionState.payload.socket.socket.disconnect();
};

const endSession = (props: IHandleMessageProps) => {
  //  disconnectFromGame(props.sessionState, props.setSessionState, { message: (props.payload.response ? props.payload.response : undefined), sendEvent: false });
};

const sessionState = (props: IHandleMessageProps) => {
    props.setSessionState({
        ...props.sessionState,
        loadingState: PromiseState.Resolved,
        payload: { ...props.sessionState.payload, ...props.payload },
    });
    //setCookie({ key: "uuid", value: props.payload.player.details.uuid });
};