import { Intent, Position, Toaster } from "@blueprintjs/core";
import { PromiseState } from "src/model/Enums";
import { IPortfolio, IPortfolioSync, RequestState } from "src/model/Models";

export interface IGetPortfolioResponse {
    success: boolean;
    data: IPortfolio[];
}

export const getPortfolioDefaultState: RequestState<IGetPortfolioResponse> = {
    loadingError: undefined,
    loadingState: PromiseState.Default,
    payload: undefined,
};

export const getPortfolio = async (): Promise<RequestState<IGetPortfolioResponse>> => {
    try {
        const response = await fetch("/api/v1/portfolio/get", { method: "GET" });
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

export interface IUpdatePercentageResponse {
    success: boolean;
    data: IPortfolio;
}

export const updatePercentageDefaultState: RequestState<IUpdatePercentageResponse> = {
    loadingError: undefined,
    loadingState: PromiseState.Default,
    payload: undefined,
};

export const updatePercentage = async (portfolioId: number, percentage: number): Promise<RequestState<IUpdatePercentageResponse>> => {
    try {
        const response = await fetch("/api/v1/portfolio/updatepercentage/"+portfolioId+"/"+percentage, { method: "GET" });
        const data = await response.json();
        if (response.ok) {
            Toaster.create({ position: Position.BOTTOM_RIGHT }).show({
                intent: Intent.SUCCESS,
                message: "Portfolio updated",
                timeout: 15000,
            });
            return {
                loadingError: undefined,
                loadingState: PromiseState.Resolved,
                payload: data,
            };
        }

        Toaster.create({ position: Position.BOTTOM_RIGHT }).show({
            intent: Intent.WARNING,
            message: "Failed to save portfolio",
            timeout: 15000,
        });
        return {
            loadingError: data,
            loadingState: PromiseState.Rejected,
            payload: undefined,
        };
    } catch (error) {
        Toaster.create({ position: Position.BOTTOM_RIGHT }).show({
            intent: Intent.DANGER,
            message: "Unexpected error occurred ",
            timeout: 15000,
        });
        return {
            loadingError: error || "An error occured",
            loadingState: PromiseState.Rejected,
            payload: undefined,
        };
    }
};

export interface ISyncBinanceResponse {
    success: boolean;
    data: IPortfolioSync[];
}

export const syncBinanceDefaultState: RequestState<ISyncBinanceResponse> = {
    loadingError: undefined,
    loadingState: PromiseState.Default,
    payload: undefined,
};

export const syncBinancePortfolio = async (): Promise<RequestState<ISyncBinanceResponse>> => {
    try {
        const response = await fetch("/api/v1/portfolio/sync", { method: "GET" });
        const data: ISyncBinanceResponse = await response.json();
        if (response.ok) {
            console.log(data);
            Toaster.create({ position: Position.BOTTOM_RIGHT }).show({
                intent: Intent.SUCCESS,
                message: "Portfolio updated",
                timeout: 15000,
            });
            data.data.filter(x => x.error && x.error !== "").forEach(x => {
                Toaster.create({ position: Position.BOTTOM_RIGHT }).show({
                    intent: Intent.WARNING,
                    message: x.error + "  |  " + x.slug,
                    timeout: 10*60*1000,
                });
            });
            return {
                loadingError: undefined,
                loadingState: PromiseState.Resolved,
                payload: data,
            };
        }

        Toaster.create({ position: Position.BOTTOM_RIGHT }).show({
            intent: Intent.WARNING,
            message: "Failed to save portfolio",
            timeout: 15000,
        });
        return {
            loadingError: data,
            loadingState: PromiseState.Rejected,
            payload: undefined,
        };
    } catch (error) {
        Toaster.create({ position: Position.BOTTOM_RIGHT }).show({
            intent: Intent.DANGER,
            message: "Unexpected error occurred ",
            timeout: 15000,
        });
        return {
            loadingError: error || "An error occured",
            loadingState: PromiseState.Rejected,
            payload: undefined,
        };
    }
};

// get "/portfolio/add", Api.PortfolioController, :add
// get "/portfolio/remove/:symbol", Api.PortfolioController, :remove
// get "/portfolio/sync", Api.PortfolioController, :sync