import { AnchorButton, HTMLTable, NumericInput } from "@blueprintjs/core";
import React, { useEffect, useState } from "react";
import { updatePercentage } from "src/actions/portfolio_actions/PortfolioActions";

import { IPortfolio } from "src/model/Models";

import "./MainTable.css";

export interface MainTableProps {
    portfolio: IPortfolio[];
}

export const MainTable: React.FC<MainTableProps> = (props) => {
    return (
        <HTMLTable striped={true} >
            <thead>
                <tr>
                    <th>Coin</th>
                    <th>Holding</th>
                    <th>Min-Holdings</th>
                    <th>Peak-Price</th>
                    <th>Min-Price</th>
                    <th>Sell Percentage</th>
                    <th></th>
                </tr>
            </thead>
            <tbody>
                {props.portfolio
                    .map(x => {x.currency.priceData = x.currency.priceData.sort((b,a) => Date.parse(a.date) - Date.parse(b.date)); return x;})
                    .filter((x) => (x.volume * x.currency.priceData[0]?.price) > 5)
                    .sort((a,b) => (b.currency.priceData[0].price * b.volume) - (a.currency.priceData[0].price * a.volume))
                    .map((e) => <MainTableRow key={e.id} {...e} />)}
            </tbody>
        </HTMLTable>
    );
};

const MainTableRow: React.FC<IPortfolio> = (props) => {

    const holding = (props.currency.priceData[0]?.price * props.volume);
    const peakPrice = props.peakPrice;
    const [sellPercentage, setSellPercentage] = useState(props.percentageChangeRequirement);
    const [sellingAt, setSellingAt] = useState(0);
    useEffect(() => {
        setSellingAt(peakPrice - peakPrice / 100 * sellPercentage);
    }, [sellPercentage]);

    const updateHandler = () => {
        updatePercentage(props.id, sellPercentage);
    };

    return (
        <tr>
            <td>{props.currency?.name}</td>
            <td>${(holding).toFixed(2)} </td>
            <td>${(sellingAt * props.volume).toFixed(2)}</td>
            <td>${peakPrice} </td>
            <td>${sellingAt.toFixed(8)} </td>
            <td>
                <NumericInput
                    allowNumericCharactersOnly={true}
                    min={0}
                    max={100}
                    value={sellPercentage}
                    leftIcon={"percentage"}
                    onValueChange={(e) => setSellPercentage(e)} />
            </td>
            <td>
                <AnchorButton type={"button"} intent={"none"} onClick={updateHandler}>Update</AnchorButton>
            </td>
        </tr>
    );
};