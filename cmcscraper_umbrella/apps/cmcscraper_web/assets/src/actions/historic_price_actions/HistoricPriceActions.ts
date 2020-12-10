import { PromiseState } from "src/model/Enums";
import { ICoin, RequestState } from "src/model/Models";


export const fetchHistoricDataDefaultState: RequestState<IFetchHistoricDataResponse> = {
    loadingError: undefined,
    loadingState: PromiseState.Default,
    payload: undefined,
};

export interface IFetchHistoricDataResponse {
    coins: ICoin[];
}

export const fetchHistoricData = async (): Promise<RequestState<IFetchHistoricDataResponse>> => {
    try {
        const response = await fetch("/api/v1/historic_price", { method: "GET" });
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