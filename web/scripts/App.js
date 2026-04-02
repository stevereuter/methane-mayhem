import { getImage, getRandomConnector, getRandomObstacle } from "./game/service.js";
import { getStart, getEnd } from "./game/level.js";
import { SpriteManager } from "./sprite/SpriteManager.js";
import { GridObject } from "./game/GridObject.js";
import { SpriteText } from "./sprite/SpriteText.js";
import { Sprite } from "./sprite/Sprite.js";

//#region Properties.

let game = {};
const player = {};
let countdown;// level property
let pipes;// level property
let pipeNumber;// level property
const grid = [];// level property
let spriteManager;
let obstacles;// level property
const state = {
    pause: 0,
    run: 1,
    end: 2,
    processing: 3
};

// rendering properties
let midgroundContext;
let foregroundContext;

//#endregion

// draw methods
/**
 * 
 * @param {CanvasRenderingContext2D} ctx canvas context
 */
function drawButtons(ctx) {

    ctx.strokeStyle = 'black';
    ctx.font = '80px Arial';

    for (let i = 0; i < 300; i += 100) {

        ctx.fillStyle = 'red';
        ctx.fillRect(i + 10, 710, 80, 80);
        ctx.strokeRect(i + 10, 710, 80, 80);

        ctx.fillStyle = 'black';

        ctx.fillText((i + 100) / 100, i + 20, 780);
    }
}

/**
 * 
 * @param {CanvasRenderingContext2D} ctx canvas context
 * @param {img} image background image
 */
function drawGrid(ctx, image) {
    ctx.clearRect(0, 0, 800, 800);
    ctx.drawImage(image, 0, 0, 800, 800);
}

/**
 * 
 * @param {CanvasRenderingContext2D} ctx canvas context
 */
function drawBorder(ctx) {

    ctx.strokeStyle = 'black';

    ctx.strokeRect(0, 0, 800, 800);
}

/**
 * 
 * @param {CanvasRenderingContext2D} ctx canvas context
 */
function drawConnectors(ctx) {

    // Starting point
    ctx.drawImage(game.images.sprites, 200, 100, 100, 100, -50, getStart() * 100 + 100, 100, 100);

    // Finishing point
    ctx.drawImage(game.images.sprites, 200, 100, 100, 100, 750, getEnd() * 100 + 100, 100, 100);

}

/**
 * @deprecated
 * @param {CanvasRenderingContext2D} ctx canvas context
 */
function drawConveyor(ctx) {

    // Platform
    ctx.fillStyle = 'black';
    ctx.fillRect(210, 90, 80, 5);
    // Belt
    ctx.beginPath();
    ctx.moveTo(0, 60);
    ctx.lineTo(200, 60);
    ctx.arc(200, 70, 10, 1.5 * Math.PI, .5 * Math.PI, false);
    ctx.lineTo(0, 80);
    ctx.closePath();
    ctx.stroke();

    // Wheels
    for (let x = 0; x <= 200; x += 20) {

        ctx.beginPath();
        ctx.arc(x, 70, 7, 0, 2 * Math.PI, false);
        ctx.closePath();
        ctx.stroke();
    }

}

/**
 * 
 * @param {CanvasRenderingContext2D} ctx canvas context
 */
function drawLifeMeter(ctx) {

    ctx.strokeStyle = 'black';
    ctx.fillStyle = 'darkred';

    const level = 300 - (300 * (countdown / 100));

    ctx.fillRect(450, 735, level, 40);
    ctx.strokeRect(450, 735, 300, 40);

}

/**
 * 
 * @param {CanvasRenderingContext2D} ctx canvas context
 */
function drawLifeCount(ctx) {

    ctx.strokeStyle = 'black';
    ctx.fillStyle = 'darkred';

    const text = player.lives;
    ctx.font = '40pt Arial';

    ctx.fillText(text, 755, 774);
    ctx.strokeText(text, 755, 774);
}

/**
 * 
 * @param {CanvasRenderingContext2D} ctx canvas context
 */
function drawPipe(ctx, x, y, type, size) {

    if (!size) {

        size = 1;
    }

    let clipX, clipY, clipW, clipH, width, height;

    width = 100 * size;
    height = 100 * size;
    clipW = 100;
    clipH = 100;

    type = type.replace(/"/g, '');

    // Service "ns", "ew", "ne", "es", "sw", "wn"

    switch (type) {
        case 'ns':
            clipX = 100;
            clipY = 0;
            break;
        case 'ew':
            clipX = 200;
            clipY = 100;
            break;
        case 'ne':
            clipX = 100;
            clipY = 100;
            break;
        case 'es':
            clipX = 0;
            clipY = 100;
            break;
        case 'sw':
            clipX = 0;
            clipY = 0;
            break;
        case 'wn':
            clipX = 200;
            clipY = 0;
            break;
        case 'cow':
            clipX = 0;
            clipY = 200;
            break;
        case 'tree':
            clipX = 0;
            clipY = 300;
            break;
        case 'rock':
            clipX = 200;
            clipY = 200;
            break;
        default:
            //alert(type);
    }

    ctx.drawImage(game.images.sprites, clipX, clipY, clipW, clipH, x, y, width, height);
}

/**
 * 
 * @param {CanvasRenderingContext2D} ctx canvas context
 */
function drawCell(ctx, x, y, type) {

    const pos = { x: 0, y: 0 };
    pos.x = x * 100 + game.area.x;
    pos.y = y * 100 + game.area.y;

    drawPipe(ctx, pos.x, pos.y, type);
}

/**
 * 
 * @param {CanvasRenderingContext2D} ctx canvas context
 */
function drawGridContent(ctx) {


    for (let i in grid) {

        const x = Math.floor(i / 10);
        const y = i % 10;

        const cell = grid[i].type;

        if (cell) {

            drawCell(ctx, x, y, cell);
        }
    }
}

/**
 * 
 * @param {CanvasRenderingContext2D} ctx canvas context
 */
function drawNext(ctx) {

    for (let i = 0; i < 4; i++) {

        let offsetY = 0;
        let offsetX = 0;

        if (pipes[pipeNumber + i].indexOf('n') >= 0 && pipes[pipeNumber + i].indexOf('s') < 0) {

            offsetY = 10;
        }
        if (pipes[pipeNumber + i].indexOf('s') >= 0 && pipes[pipeNumber + i].indexOf('n') < 0) {

            offsetY = -10;
        }
        if (pipes[pipeNumber + i].indexOf('e') >= 0 && pipes[pipeNumber + i].indexOf('w') < 0) {

            offsetX = -10;
        }
        if (pipes[pipeNumber + i].indexOf('w') >= 0 && pipes[pipeNumber + i].indexOf('e') < 0) {

            offsetX = 10;
        }

        drawPipe(ctx, 215 + offsetX - (i * 70), (i ? 15 : 5) + offsetY, pipes[pipeNumber + i], (i ? .6 : .8));

    }
}

/**
 * 
 * @param {CanvasRenderingContext2D} ctx canvas context
 */
function drawBackground(ctx) {

    drawGrid(ctx, game.images.bg);

    drawBorder(ctx);

    drawConnectors(ctx);

    //drawConveyor(ctx);

    drawLifeCount(ctx);
    drawButtons(ctx);
}

function drawMidGround(ctx) {

    ctx.clearRect(0, 0, 800, 800);

    drawGridContent(ctx);
    drawNext(ctx);

    if (game.state === state.pause || game.state === state.end) {
        // TODO: Get from pause object
        ctx.fillStyle = 'rgba(0,0,0,0.5)';
        ctx.fillRect(0, 0, 800, 800);

        if (game.state === state.pause) {

            const text = 'Paused';
            ctx.font = '100px Arial';
            const textLength = ctx.measureText(text);
            ctx.fillStyle = '#999';
            ctx.fillText(text, 400 - (textLength.width / 2), 250);

        }
    }
}

function drawForeGround(ctx) {

    ctx.clearRect(0, 0, 800, 800);

    drawLifeMeter(ctx);
    spriteManager.draw(ctx);
}

// utilities
function getRandomGridID() {

    const random = Math.floor(Math.random() * grid.length);

    if (grid[random]) {

        return random;
    } else {

        return getRandomGridID();
    }
}

function createRandomObstacles() {

    for (let i in obstacles) {

        const id = getRandomGridID();

        grid[id].create(obstacles[i]);
    }

}

function getMaxStart(previous, current) {

    const currentStart = (current === undefined ? 0 : current.start);
    return Math.max(previous, currentStart);
}

// update methods
function removeStartConnection(startNumber) {

    for (let i in grid) {

        if (grid[i].start >= startNumber) {

            grid[i].update(0);
        }
    }
}

function removeEndConnection(endNumber) {

    for (let i in grid) {


        if (grid[i].end >= endNumber) {

            grid[i].update(undefined, 0);
        }
    }
}

function updateConnectionBySibling(pipeID, siblingID) {

    let newStart = undefined, newEnd = undefined;


    if (grid[siblingID].start) {

        newStart = grid[siblingID].start + 1;
        removeStartConnection(newStart);
    }
    if (grid[siblingID].end) {

        newEnd = grid[siblingID].end + 1;
        removeEndConnection(newEnd);
    }

    grid[pipeID].update(newStart, newEnd);

    if (grid[pipeID].start && grid[pipeID].end) {

        // Game over
        return 2;
    }
    return 1;
}

function updateConnectedState(gridID) {

    let newState = state.run;

    const x = Math.floor(gridID / 10);
    const y = gridID % 10;

    // Check if next to start
    if (x === 0 && y === getStart() && grid[gridID].w) {

        removeStartConnection(1);
        grid[gridID].update(1);
    }
    // Check if next to end
    if (x === 6 && y === getEnd() && grid[gridID].e) {

        removeEndConnection(1);
        grid[gridID].update(undefined, 1);
    }

    // Check if connected
    if (grid[gridID].n && grid[gridID - 1] && (grid[gridID - 1].s && (grid[gridID - 1].start || grid[gridID - 1].end))) {

        newState = updateConnectionBySibling(gridID, gridID - 1);
    }
    if (grid[gridID].e && grid[gridID + 10] && (grid[gridID + 10].w && (grid[gridID + 10].start || grid[gridID + 10].end))) {

        newState = updateConnectionBySibling(gridID, gridID + 10);
    }
    if (grid[gridID].s && grid[gridID + 1] && (grid[gridID + 1].n && (grid[gridID + 1].start || grid[gridID + 1].end))) {

        newState = updateConnectionBySibling(gridID, gridID + 1);
    }
    if (grid[gridID].w && grid[gridID - 10] && (grid[gridID - 10].e && (grid[gridID - 10].start || grid[gridID - 10].end))) {

        newState = updateConnectionBySibling(gridID, gridID - 10);
    }

    // Check next
    if (grid[gridID].start || grid[gridID].end) {

        switch (true) {
            case grid[gridID].n && grid[gridID - 1] && grid[gridID - 1].s && !(grid[gridID - 1].start || grid[gridID - 1].end):

                return updateConnectedState(gridID - 1);
            case grid[gridID].e && grid[gridID + 10] && grid[gridID + 10].w && !(grid[gridID + 10].start || grid[gridID + 10].end):

                return updateConnectedState(gridID + 10);
            case grid[gridID].s && grid[gridID + 1] && grid[gridID + 1].n && !(grid[gridID + 1].start || grid[gridID + 1].end):

                return updateConnectedState(gridID + 1);
            case grid[gridID].w && grid[gridID - 10] && grid[gridID - 10].e && !(grid[gridID - 10].start || grid[gridID - 10].end):

                return updateConnectedState(gridID - 10);

        }
    }

    return newState;
}

// core game methods
function getPosition(event) {

    const position = {};

    // Get x and y
    if (event.pageX || event.pageY) {
        position.x = event.pageX;
        position.y = event.pageY;
    }
    else {
        position.x = event.clientX + document.body.scrollLeft + document.documentElement.scrollLeft;
        position.y = event.clientY + document.body.scrollTop + document.documentElement.scrollTop;
    }
    position.x -= event.target.offsetLeft;
    position.y -= event.target.offsetTop;

    // Get the game grid on the canvas
    position.canvasX = position.x - game.area.x;
    position.canvasY = position.y - game.area.y;

    // Get the cell x and y on the grid
    position.gridX = Math.floor(position.canvasX / 100);
    position.gridY = Math.floor(position.canvasY / 100);

    // Get specific areas on the canvas
    position.isGameArea = position.x >= game.area.x && position.x <= (game.area.w + game.area.x) && position.y >= game.area.y && position.y <= (game.area.h + game.area.y);
    position.isButtonArea = !position.isGameArea && position.x < game.area.bw && position.y > game.area.h;

    return position;
}

function performPlayerMove(pos) {

    const gridID = (pos.gridX * 10) + pos.gridY;
    const currentStart = grid.reduce(getMaxStart, 0);

    if (player.powerUp) {

        grid[gridID].create('');
        player.powerUp = false;

        // TODO: need to get the new connected length to see if we need to add to the game life
        if (countdown > 0) {

            countdown -= 10;
        }
    } else {

        player.totalMoves += 1;

        // Check if cell is available
        switch (grid[gridID].type) {
            // Obstacles
            case 'cow':
            case 'rock':
            case 'tree':
                const text = new SpriteText('Blocked!', 20, { r: 255, g: 0, b: 0 }, pos.gridX * 100 + 100, pos.gridY * 100 + 100, { r: 0, g: 0, b: 0 });
                const sprite = new Sprite(text, pos.gridX * 100 + 100, pos.gridY * 100 + 75, 1000);
                spriteManager.add(sprite);
                break;
            default:
                // Check if an existing pipe with a start or end is being replaced
                if (grid[gridID].start) {
                    
                    removeStartConnection(grid[gridID].start);
                }
                if (grid[gridID].end) {
                    
                    removeEndConnection(grid[gridID].end);
                }
                
                grid[gridID].create(pipes[pipeNumber]);
                
                pipeNumber += 1;

                // check connected status here.
                game.state = updateConnectedState(gridID);


                const newStart = grid.reduce(getMaxStart, 0);
                const difference = (newStart - currentStart) * 10;

                if (countdown > 0) {

                    countdown += difference;
                    countdown -= 10;
                }

                if (game.state === state.end) {

                    const length = grid[gridID].start + (grid[gridID].end - 1);
                    const width = player.totalMoves - length;

                    const message = 'Pipeline length: ' + length.toString() + ', Wasted pipes: ' + width.toString();
                    const text = new SpriteText(message, 40, '#fff', 400, 0, '#000');

                    const sprite = new Sprite(text, 400, 250, 1000, function (txtSprite) {

                        const mg = document.getElementById('game-mg');
                        const ctx = mg.getContext('2d');

                        txtSprite.draw(ctx);
                    });
                    spriteManager.add(sprite);
                }
        }
    }
}

function feedConveyor() {

    if (pipeNumber + 5 > pipes.length) {

        const newPipes = getRandomConnector(7);
        const arr = pipes.concat(newPipes);
        pipes = arr;
    }

}

function createClickEvents() {

    function fgClick(event) {

        player.click = event;
    }

    const fg = document.getElementById('game-fg');
    fg.addEventListener('click', fgClick);
}

function createGrid() {

    grid.length = 0;


    for (let y = 0; y < 6; y += 1) {
        for (let x = 0; x < 70; x += 10) {

            grid[x + y] = new GridObject();
        }
    }
}

function resetGame(lifeUsed) {

    if (lifeUsed) {

        player.lives = player.lives - 1;
    } else {

        player.lives = 3;
    }

    // TODO: Set a new pause state
    game.state = state.pause;
    game.start = new Date().getTime();
    countdown = 100;
    game.speed = 10;
    pipeNumber = 0;
    player.totalMoves = 0;
    spriteManager = new SpriteManager();
    pipes = [];
    createGrid();
    player.powerUp = false;

    game.area = {
        x: 50, y: 100, w: 700, h: 600, bw: 300
    };

    feedConveyor();

    const list = getRandomObstacle(5);
    obstacles = list;

    gameStart();
}

// main engine
function update() {

    if (player.click) {

        const position = getPosition(player.click);

        player.click = undefined;

        switch (game.state) {
            case state.pause:
                // TODO: Need a pause method for processing pause actions
                // TODO: Actions: Pending start, selection is required, instruction displayed
                game.state = state.run;
                drawMidGround(midgroundContext);
                break;
            case state.run:
                // Game is running
                if (position.isGameArea) {

                    performPlayerMove(position);

                    feedConveyor();

                    drawMidGround(midgroundContext);

                }

                if (position.isButtonArea) {

                    player.powerUp = true;
                }

                break;
            case state.end:
                // TODO: Game over. Determine options
                resetGame(0);
                break;
            case state.processing:
                // No player action allowed
            default:

                break;
        }
    }

    spriteManager.update();

}

function draw() {

    drawForeGround(foregroundContext);
}

function loop() {

    // Update
    update();

    // Draw
    draw();

    // Next loop
    window.requestAnimationFrame(loop);
}

function gameStart() {

    const background = document.getElementById('game-bg');
    const backgroundContext = background.getContext('2d');
    const midground = document.getElementById('game-mg');
    midgroundContext = midground.getContext('2d');
    const foreground = document.getElementById('game-fg');
    foregroundContext = foreground.getContext('2d');



    drawBackground(backgroundContext);
    createRandomObstacles();
    drawMidGround(midgroundContext);
    drawForeGround(foregroundContext);

    loop();
}


async function init() {

    window.requestAnimationFrame = (function (callback) {
        return window.requestAnimationFrame ||
            window.webkitRequestAnimationFrame ||
        window.mozRequestAnimationFrame ||
        window.oRequestAnimationFrame ||
        window.msRequestAnimationFrame ||
        function (callback) {
            window.setTimeout(callback, 1000 / 60);
        };
    }());

    game.start = 0;
    game.speed = 0;
    game.area = { x: 0, y: 0, w: 0, h: 0, bw: 0 };
    game.images = {};
    game.state = state.pause;

    player.lives = 0;
    player.totalMoves = 0;
    player.click = undefined;
    player.powerUp = false;

    // TODO: need to run in parallel
    game.images.sprites = await getImage("images/spritesheet.png");
    game.images.bg = await getImage("images/gameboard7x6.jpg");

    createClickEvents();
    resetGame();
}

init();
