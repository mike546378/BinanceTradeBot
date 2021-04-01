import { PromiseState } from "src/model/Enums";
import { RequestState } from "src/model/Models";

export interface IGetAnalysisResponse {
    success: boolean;
    data: any[];
}

export const getAnalysisDefaultState: RequestState<IGetAnalysisResponse> = {
    loadingError: undefined,
    loadingState: PromiseState.Default,
    payload: undefined,
};

export const getAnalysis = async (): Promise<RequestState<IGetAnalysisResponse>> => {
    try {
        const response = await fetch("/api/v1/data/analysis", { method: "GET" });
        const data = await response.json();

        if (response.ok) {
            console.log(data);
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