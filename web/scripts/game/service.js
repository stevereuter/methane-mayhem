/** @format */

const CONNECTORS = ['ns', 'ew', 'ne', 'es', 'sw', 'wn'];
const OBSTACLES = ['cow', 'tree', 'rock'];

export async function getImage(path) {
    return new Promise((resolve) => {
        const image = new Image();
        image.src = path;
        image.onload = () => resolve(image);
    });
}

export function getRandomConnector(qty) {
    const store = [...CONNECTORS, ...CONNECTORS];
    const connectors = new Array(qty);

    for (let i = 0; i < qty; i += 1) {
        const randomIndex = Math.floor(Math.random() * store.length);
        const randomConnector = store[randomIndex];
        connectors[i] = randomConnector;
        store.splice(randomIndex, 1);
    }

    return connectors;
}

export function getRandomObstacle(qty) {
    const obstacles = [];

    do {
        const randomIndex = Math.floor(Math.random() * OBSTACLES.length);
        const randomObstacle = OBSTACLES[randomIndex];

        obstacles.push(randomObstacle);
    } while (obstacles.length <= qty);

    return obstacles;
}
