import { Button, Intent, Position, Toaster } from "@blueprintjs/core";
import React, { useEffect, useState } from "react";
import { getAnalysis } from "src/actions/data_actions/DataActions";
import { getPortfolio, getPortfolioDefaultState, IGetPortfolioResponse, syncBinancePortfolio } from "src/actions/portfolio_actions/PortfolioActions";

import { PromiseState, UpdateStatus } from "src/model/Enums";
import { ISessionState, RequestState } from "src/model/Models";
import { MainTable } from "./MainTable";

import "./MainTable.css";

export const MainTableContainer: React.FC<ISessionState> = (props) => {

    const buttonProps = { large: true, loading: false, fill: true };
    const [portfolio, setPortfolio] = useState(getPortfolioDefaultState);
    const [updatePortfolio, setUpdatePortfolio] = useState(false);
    useEffect(() => {
        setPortfolio(getPortfolioDefaultState);
        getPortfolio()
            .then((result: RequestState<IGetPortfolioResponse>) => {
                setPortfolio(result);
                if (result.loadingState === PromiseState.Rejected) {
                    Toaster.create({ position: Position.BOTTOM_RIGHT }).show({
                        intent: Intent.WARNING,
                        message: result.loadingError.message || "An error ocurred, please try again",
                        timeout: 5000,
                    });
                }
            });
    }, []);

    const syncBinance = () => { syncBinancePortfolio(); };
    const historyUpdate = () => { setUpdatePortfolio(!updatePortfolio); };
    const cmcAnalysis = () => { getAnalysis(); };

    const mainTable =
        portfolio.loadingState === PromiseState.Resolved ?
            <MainTable portfolio={portfolio.payload.data} />
            : <></>;
    return (
        <MainTableWrapper>
            <MenuButtonWrapper>
                <Button
                    {...buttonProps}
                    disabled={props.updateStatus && props.updateStatus !== UpdateStatus.Updating}
                    loading={props.updateStatus && props.updateStatus !== UpdateStatus.Updating}
                    onClick={syncBinance}>Sync With Binance</Button>
                <Button
                    {...buttonProps}
                    disabled={props.updateStatus && props.updateStatus !== UpdateStatus.Updating}
                    loading={props.updateStatus && props.updateStatus !== UpdateStatus.Updating}
                    onClick={historyUpdate}>Refresh Coin List</Button>
                <Button
                    {...buttonProps}
                    disabled={props.updateStatus && props.updateStatus !== UpdateStatus.Updating}
                    loading={props.updateStatus && props.updateStatus !== UpdateStatus.Updating}
                    onClick={cmcAnalysis}>CMC Analysis</Button>
            </MenuButtonWrapper>
            {mainTable}
        </MainTableWrapper>
    );
};

const MenuButtonWrapper: React.FC = (props) => (
    <div className="menu-button-wrapper">
        {props.children}
    </div>
);

const MainTableWrapper: React.FC = (props) => (
    <div className="main-table-wrapper">
        {props.children}
    </div>
);