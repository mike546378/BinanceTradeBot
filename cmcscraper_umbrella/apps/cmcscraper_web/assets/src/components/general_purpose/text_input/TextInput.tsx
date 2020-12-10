import { InputGroup } from "@blueprintjs/core/lib/esm/components/forms/inputGroup";
import React from "react";
import { ITextInputProps } from "src/model/Models";


export const TextInputLarge: React.FC<ITextInputProps> = (props) => {
    return (
        <InputGroup
            className="text-input-field"
            large={true}
            fill={true}
            placeholder={props.placeholder}
            type="text"
            value={props.text}
            onChange={(e) => props.setText(e.target.value)}
        />
    );
};

export default TextInputLarge;