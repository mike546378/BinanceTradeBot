
export interface ISetCookie {
    key: string; value: string;
}
export const setCookie = (props: ISetCookie) => {
    const date = new Date();
    date.setTime(date.getTime() + (10 * 365 * 7 * 24 * 60 * 60 * 1000));
    document.cookie = props.key + "=" + props.value + "; expires=" + date.toUTCString() + "; path=/";
};

export interface IGetCookie {
    key: string;
}
export const getCookie = (props: IGetCookie): string => {
    const value = "; " + document.cookie;
    const parts = value.split("; " + props.key + "=");

    if (parts.length === 2) {
        return parts.pop().split(";").shift();
    }
    return undefined;
};
