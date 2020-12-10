import * as React from "react";
import Footer from "src/components/structural/global/footer/FooterStructure";
import Header from "src/components/structural/global/header/HeaderStructure";
import "./BaseStructure.css";

const BaseStructure: React.FC<any> = (props) => (
    <div className="App bp3-dark">
        <Header />
            {props.children}
        <Footer />
    </div>
);

//{props.children}
export default BaseStructure;