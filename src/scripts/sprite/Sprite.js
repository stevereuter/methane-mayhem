// Dependencies:
// ImageLoop
// ImageStatic
// SpriteText

export function Sprite(spriteImage, endX, endY, speed, callback) {
    //#region Properties.
    const start = {
        x: spriteImage.x(),
        y: spriteImage.y(),
        time: Date.now()
    };
    const difference = {
        x: endX - start.x,
        y: endY - start.y,
    };
    let done = false;
    //#endregion

    //#region Methods.

    function update() {

        const current = Date.now();
        const percent = (current - start.time) / speed;

        // Check status
        if (percent < 1) {

            const x = (difference.x * percent) + start.x;
            const y = (difference.y * percent) + start.y;

            spriteImage.update(x, y, 1 - percent);

        } else {

            done = true;

            if (callback) {

                callback(spriteImage);
            }
        }

    }

    function draw(ctx) {
        // Draw image
        spriteImage.draw(ctx);
    }

    function isDone() {

        return done;
    }

    //#endregion

    // Exposed methods.
    return {
        isDone: isDone,
        draw: draw,
        update: update
    };
}
