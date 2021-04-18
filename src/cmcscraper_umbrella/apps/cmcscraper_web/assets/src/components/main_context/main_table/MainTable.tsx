import { AnchorButton, HTMLTable, NumericInput } from "@blueprintjs/core";
import React, { useEffect, useState } from "react";
import { updatePercentage } from "src/actions/portfolio_actions/PortfolioActions";

import { IPortfolio, IPriceData } from "src/model/Models";

import "./MainTable.css";

export interface MainTableProps {
    portfolio: IPortfolio[];
}

export const MainTable: React.FC<MainTableProps> = (props) => {
    const dummyObj: IPriceData = { date: null, ranking: 9999, price: 999999, volume: 9999, marketcap: 9999 };

    return (
        <HTMLTable striped={true} >
            <thead>
                <tr>
                    <th>Coin</th>
                    <th>Holding</th>
                    <th>Peak-Holdings</th>
                    <th>Min-Holdings</th>
                    <th>Coins Hodling</th>
                    <th>Sell Percentage</th>
                </tr>
            </thead>
            <tbody>
                {props.portfolio
                    .map(x => {
                        x.currency.priceData = x.currency.priceData.sort((b, a) => Date.parse(a.date) - Date.parse(b.date));
                        if (x.currency.priceData[0] == null) x.currency.priceData.push(dummyObj);
                        return x;
                    })
                    .filter((x) => (x.volume * x.currency.priceData[0]?.price) > 5)
                    .sort((a, b) => (b.currency.priceData[0].price * b.volume) - (a.currency.priceData[0].price * a.volume))
                    .map((e) => <MainTableRow
                        key={e.id}
                        {...e} />)}
                <TotalsTableRow
                    portfolio={props.portfolio}
                />
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
            <td>${(peakPrice * props.volume).toFixed(2)} </td>
            <td>${(sellingAt * props.volume).toFixed(2)}</td>
            <td>{props.volume} </td>
            <td className={"update-column"}>
                <NumericInput
                    allowNumericCharactersOnly={true}
                    min={0}
                    max={100}
                    value={sellPercentage}
                    leftIcon={"percentage"}
                    onValueChange={(e) => setSellPercentage(e)} />
                <AnchorButton type={"button"} intent={"none"} onClick={updateHandler}>Update</AnchorButton>
            </td>
        </tr>
    );
};

const TotalsTableRow: React.FC<MainTableProps> = (props) => {

    const holding = props.portfolio.reduce((sum, x) => sum + x.currency.priceData[0]?.price * x.volume, 0);
    const peakHolding = props.portfolio.reduce((sum, x) => sum + x.peakPrice * x.volume, 0);
    const minHolding = props.portfolio.reduce((sum, x) => sum + x.sellingAt * x.volume, 0);

    return (
        <tr>
        <td>Totals</td>
        <td>${(holding).toFixed(2)} </td>
        <td>${(peakHolding).toFixed(2)}</td>
        <td>${(minHolding).toFixed(2)} </td>
        <td />
        <td />
    </tr>
    );
};