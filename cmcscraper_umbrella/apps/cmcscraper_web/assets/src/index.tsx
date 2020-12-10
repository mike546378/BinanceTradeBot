// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import deps with the dep name or local files with a relative path, for example:
//
//     import {Socket} from "phoenix"
//     import socket from "./socket"
//

import React from "react";
import ReactDOM from "react-dom";

import { App } from "./App";

import { BrowserRouter as Router, Route, Switch } from "react-router-dom";

const ReactRouter: React.FC = () => (
    <Router>
        <Switch>
            <Route path="/" render={(props) => <App {...props} />} />
        </Switch>
    </Router>
);

const body = document.getElementById("body");
ReactDOM.render(<ReactRouter />, body);
