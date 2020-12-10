import React from "react";

import { Divider } from "@blueprintjs/core";
import { Col, Row } from "react-bootstrap";
import { getCookie } from "src/actions/cookie_manager/CookieManager";

import TextInputLarge from "src/components/general_purpose/text_input/TextInput";
import About from "../global/info/about";

import "./Layout.css";

export const MainMenu: React.FC = () => {
    const [username, setUsername] = React.useState(getCookie({ key: "username" }) || "");
    const [gameId, setGameId] = React.useState("");
    return (
        <Row>
            <Col md={6} sm={12}>
                <About/>
            </Col>
            <Divider/>
            <Col md={5} sm={12}>
                <MainMenuWrapper>
                    <InteractableSection>
                        <TextInputLarge
                            text={username}
                            setText={setUsername}
                            placeholder="Username..."
                        />
                        <TextInputLarge
                            text={gameId}
                            setText={setGameId}
                            placeholder="Friends Game Code"
                        />
                    </InteractableSection>
                </MainMenuWrapper>
            </Col>
        </Row>);
};

const MainMenuWrapper: React.FC = (props) => (
    <div className={"main-menu-wrapper"}>
        {props.children}
    </div>
);

const InteractableSection: React.FC = (props) => (
    <div className={"interactable-section-wrapper"}>
        {props.children}
    </div>
);


export default MainMenu;