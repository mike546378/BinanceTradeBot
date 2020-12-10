import { PromiseState } from "src/model/Enums";
import { RequestState } from "src/model/Models";


export const fetchNewGameIdDefaultState: RequestState<IGameCreationResponse> = {
    loadingError: undefined,
    loadingState: PromiseState.Default,
    payload: undefined,
};

export interface IGameCreationResponse {
    gameId: string;
}

export const sendPing = async (): Promise<RequestState<IGameCreationResponse>> => {
    try {
        const response = await fetch("/api/v1/new_game", { method: "GET" });
        const data = await response.json();

        if (response.ok) {
            return {
                loadingError: undefined,
                loadingState: PromiseState.Resolved,
                payload: data,
            };
        }

        return {
            loadingError: data,
            loadingState: PromiseState.Rejected,
            payload: undefined,
        };
    } catch (error) {
        return {
            loadingError: error || "An error occured",
            loadingState: PromiseState.Rejected,
            payload: undefined,
        };
    }
};