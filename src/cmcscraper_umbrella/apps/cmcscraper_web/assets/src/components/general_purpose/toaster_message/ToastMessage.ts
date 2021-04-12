import { Position, Toaster } from "@blueprintjs/core";

export const ToastMessage = Toaster.create({
    className: "toast-message",
    position: Position.BOTTOM_RIGHT,
});