import { Navbar } from "@blueprintjs/core";
import React, {useState} from "react";
import { Redirect } from "react-router-dom";
import "./HeaderStructure.css";


const Header: React.FC<any> = (props) => {
    const [redirectBool, redirectCall] = useState(false);
    const redirect = redirectBool ? <Redirect to="/" /> : <></>;

    return(
        <Navbar>
            <div onClick={e => redirectCall(true)}>
            <Navbar.Group>
            {redirect}
                <Navbar.Heading> CmcScraper </Navbar.Heading>
                <Navbar.Divider/>
            </Navbar.Group>
            </div>
            <Navbar.Group align="right">
                <Navbar.Heading>Actions</Navbar.Heading>
            </Navbar.Group>
        </Navbar>);
};

export default Header;