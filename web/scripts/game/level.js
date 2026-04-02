
// TODO: need to move connectors and obstacles to here
// TODO: need to import configs for each level
// TODO: need to move countdown and methane status here

// export const STATE = {
//     Paused: 0,
//     Running: 1,
//     Ended: 2
// };

// let currentState = STATE.Paused;
let start = Math.floor(Math.random() * 6);
let end = Math.floor(Math.random() * 6);

// export function getState() {
//     return currentState;
// }

// export function setState(newState) {
//     currentState = newState;
// }

export function getStart() {
    return start;
}

export function getEnd() {
    return end;
}
