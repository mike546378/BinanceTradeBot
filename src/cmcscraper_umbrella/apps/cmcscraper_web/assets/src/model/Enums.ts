export enum CardType {
    situation = "situation",
    scenario = "scenario",
    counter = "counter",
}

export enum Situation {
    family = "family",
    partner = "partner",
    single = "single",
}

export enum PromiseState {
    Default,
    Pending,
    Resolved,
    Rejected,
}

export enum PlayerTurn {
    Defender = "defender",
    Attacker = "attacker",
}

export enum UpdateStatus {
    None = "none",
    Updating = "updating"
}