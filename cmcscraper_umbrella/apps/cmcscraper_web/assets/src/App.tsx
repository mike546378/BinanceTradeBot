import React from "react";
import { RouteComponentProps } from "react-router-dom";

import BaseStructure from "./components/structural/global/base/BaseStructure";
import MainMenu from "./components/structural/menu/Layout";

import "./App.css";
import { AppBase } from "./components/main_context/base/base";

export const MenuWindow: React.FC<RouteComponentProps<any>> = (_props) => {
	console.log("lol");
    return (
        <BaseStructure>
            <MainMenu />
        </BaseStructure>);
};

export const App: React.FC<RouteComponentProps<any>> = (_props) => {
    return (
        <BaseStructure>
            <AppBase />
        </BaseStructure>
    );
};
