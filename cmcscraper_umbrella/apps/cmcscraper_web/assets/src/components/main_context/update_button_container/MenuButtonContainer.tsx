import { Button, Intent, Position, Toaster } from "@blueprintjs/core";
import React, { useEffect, useState } from "react";
import { fetchHistoricData, fetchHistoricDataDefaultState, IFetchHistoricDataResponse } from "src/actions/historic_price_actions/HistoricPriceActions";

import { PromiseState, UpdateStatus } from "src/model/Enums";
import { ISessionState, RequestState } from "src/model/Models";

//import "./MenuButtonContainer.css";

export const MenuButtonContainer: React.FC<ISessionState> = (props) => {

    const buttonProps = { large: true, loading: false, fill: true };
    const fullUpdate = () => { props.socket.channel.push("full_update", {}, 10000).receive("ok", (e) => {console.log(e);});};
    const historyUpdate = () => { props.socket.channel.push("get_all_coins", {}, 10000).receive("ok", (e) => {console.log(e);});};

    const [historicData, setHistoricData] = useState(fetchHistoricDataDefaultState);
    useEffect(() => {
        setHistoricData(fetchHistoricDataDefaultState);
        fetchHistoricData()
            .then((result: RequestState<IFetchHistoricDataResponse>) => {
                setHistoricData(result);
                if (result.loadingState === PromiseState.Rejected) {
                    Toaster.create({ position: Position.BOTTOM_RIGHT }).show({
                        intent: Intent.WARNING,
                        message: result.loadingError.message || "An error ocurred, please try again",
                        timeout: 5000,
                    });
                }
            });
    }, []);


    const mainTable =
        historicData.loadingState === PromiseState.Resolved ?
            <MainTable historicData={historicData.payload} />
            : <></>;
    
    return (
        <MenuButtonWrapper>
            <Button
                {...buttonProps}
                disabled={props.updateStatus && props.updateStatus != UpdateStatus.Updating}
                loading={props.updateStatus && props.updateStatus != UpdateStatus.Updating}
                onClick={fullUpdate}>Full Update</Button>
            <Button
                {...buttonProps}
                disabled={props.updateStatus && props.updateStatus != UpdateStatus.Updating}
                loading={props.updateStatus && props.updateStatus != UpdateStatus.Updating}
                onClick={historyUpdate}>Refresh Coin List</Button>
            {mainTable}
        </MenuButtonWrapper>
    );
};

const MenuButtonWrapper: React.FC = (props) => (
    <div className="menu-button-wrapper">
        {props.children}
    </div>
);