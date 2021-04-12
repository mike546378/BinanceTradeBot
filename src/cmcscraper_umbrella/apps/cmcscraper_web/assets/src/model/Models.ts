import { Channel, Socket } from "phoenix";
import { CardType, PlayerTurn, PromiseState, Situation, UpdateStatus } from "./Enums";

export interface ICard {
    name: string;
    description: string;
    image: string;
    cost: number;
    cardId: number;
    cardType: CardType;
    active: boolean;
    toggleActive: (index: any) => any;
}

export interface ITextInputProps {
    text: string;
    setText: React.Dispatch<React.SetStateAction<string>>;
    placeholder: string;
}

export interface IPlayerDetails {
    username: string;
    uuid: string;
    public_uuid: string;
}
export interface IPlayerState {
    details: IPlayerDetails;
    cards: ICard[];
    situation: Situation;
}

export interface IOpponentState {
    details: IPlayerDetails;
    numCards: number;
}

export interface IGameState {
    game_started: boolean;
    players: IOpponentState[];
    currentDefender: string;
    currentAttacker: string;
    turn: PlayerTurn;
    lastCard: ICard;
    prizePool: number;
}

export interface ISocketConnection {
    socket: Socket;
    channel: Channel;
}

export interface ISessionState {
    socket?: ISocketConnection;
    updateStatus?: UpdateStatus;
}

export interface ISessionRequestState extends RequestState<ISessionState> { }

export interface RequestState<T> {
    loadingState: PromiseState;
    loadingError: any;
    payload: T;
}

export interface SocketMessage<T> {
    event: string;
    payload: T;
}

export interface ICoin {
    name: string;
    priceData: IPriceData[];
}

export interface IPriceData {
    date: string;
    ranking: number;
    price: number;
    volume: number;
    marketcap: number;
}

export interface ICurrency {
    id: number;
    name: string;
    symbol: string;
    dateCreated: string;
    dateUpdated: string;
    priceData: IPriceData[];
}

export interface IPortfolio {
    id: number;
    purchaseDate: string;
    purchasePrice: number;
    percentageChangeRequirement: number;
    volume: number;
    sellPrice: number;
    sellDate: string;
    profit: number;
    peakPrice: number;
    sellingAt: number;
    currency: ICurrency;
}

export interface IPortfolioSync extends IPortfolio {
    error: string;
    slug: string;
}