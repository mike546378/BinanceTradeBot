//#region Imports

// external
import { Icon, Intent, Spinner } from "@blueprintjs/core";
import * as React from "react";
import { RotateSpinner } from "react-spinners-kit";

// styles
import "./PageLoaders.css";

//#endregion

export const SpinningLoader: React.FC = (props) => (
    <div className="app-loader">
        <RotateSpinner size={Spinner.SIZE_LARGE} />
        {props.children}
    </div>
);

export const ErrorLoader: React.FC<{ message: string }> = (props) => (
    <div className="app-loader">
        <Icon icon="warning-sign" iconSize={100} intent={Intent.WARNING} />
        <h1>{props.message}</h1>
        {props.children}
    </div>
);

export default SpinningLoader;