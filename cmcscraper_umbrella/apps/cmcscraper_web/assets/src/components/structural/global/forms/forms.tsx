import React from "react";

import TextInputLarge from "src/components/general_purpose/text_input/TextInput";
import "./Layout.css";

export const MainMenuForm: React.FC = () => {
    const [username, setUsername] = React.useState("");
    const [gameId, setGameId] = React.useState("");

    return (<MainMenuWrapper>
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
    </MainMenuWrapper>);
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


export const SetUsername: React.FC = () => {
    const [username, setUsername] = React.useState("");

    return (<InteractableSection>
        <TextInputLarge
            text={username}
            setText={setUsername}
            placeholder="Username..."
        />
    </InteractableSection>);
};



export default MainMenuForm;