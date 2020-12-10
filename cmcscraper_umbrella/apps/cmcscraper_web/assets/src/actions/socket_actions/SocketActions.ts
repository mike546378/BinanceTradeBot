import { Socket } from "phoenix";
import { PromiseState } from "src/model/Enums";
import { ISessionRequestState, ISessionState, ISocketConnection, RequestState } from "src/model/Models";

export const defaultSessionState: ISessionState = {
    socket: undefined,
    updateStatus: undefined,
};

export const sessionConnectionDefaultState: RequestState<ISessionState> = {
    loadingError: undefined,
    loadingState: PromiseState.Default,
    payload: defaultSessionState,
};

export interface IMessageHandler {
    onMessage: (e: any, payload: any, ref: any) => any;
    onError: (e: any) => void;
    onClose: (e: any) => void;
    onJoin: (e: any) => void;
}

export const socketCallbacks: IMessageHandler = {
    onError: (e) => (console.log({SocketActionsError: e})),// console.log({ err: "Sock error", e })),
    onClose: (e) => (console.log({ SockClosing: e })),
    onMessage: (e, p, r) => { console.log({ SocketActionsMessage: "New message", e }); return p; },
    onJoin: (e) => (console.log("Sock joined")),
};

export const connectToSocket = async (sessionState: ISessionState, callbacks: IMessageHandler): Promise<RequestState<ISessionState>> => {
        const sock = new Socket("/socket");
        sock.connect();
        const channel = sock.channel("updatestatus", {});
        channel.join();

        const socketConnection: ISocketConnection = { socket: sock, channel };

        channel.onError = callbacks.onError;
        channel.onMessage = callbacks.onMessage;
        channel.onClose = callbacks.onClose;
        sock.onError(callbacks.onError);
        sock.onClose(callbacks.onClose);
        sock.onOpen((e) => callbacks.onJoin(e));
        return connectionState(sessionState, socketConnection);
};

interface IDisconnectArgs { message?: string; pending?: boolean; }
export const disconnectFromSocket = (state: ISessionRequestState, setState: React.Dispatch<React.SetStateAction<ISessionRequestState>>, args?: IDisconnectArgs) => {
    console.log("Disconnect!");
    const socketConnection: ISocketConnection = state.payload.socket;
    if (socketConnection?.socket?.isConnected()) {
        socketConnection.channel.leave();
        setState({
            ...state,
            loadingState: (args.pending ? PromiseState.Pending : PromiseState.Rejected),
            loadingError: { message: (args.message ? args.message : "Disconnected") },
        });
        socketConnection.socket.disconnect();
    }
};

export const connectionState = (sessionState: ISessionState, sock: ISocketConnection) => {
   try{
    if (sock.socket.isConnected()) {
            return {
                loadingError: undefined,
                loadingState: PromiseState.Resolved,
                payload: { ...sessionState, socket: sock },
            };
        } else if (sock.socket.connectionState() === "connecting")
            return {
                loadingError: undefined,
                loadingState: PromiseState.Pending,
                payload: { ...sessionState, socket: sock },
            };

        return {
            loadingError: "An error occured establishing the connection",
            loadingState: PromiseState.Rejected,
            payload: { ...sessionState, socket: sock },
        };
    } catch (error) {
        return {
            loadingError: error.toString() || "An error occured establishing the connection",
            loadingState: PromiseState.Rejected,
            payload: undefined,
        };
    }
}