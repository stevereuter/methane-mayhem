

export function SpriteManager() {
    //#region Properties.

    const sprites = [];

    //#endregion

    //#region Methods.

    function add(newSprite) {

        sprites.push(newSprite);
    }

    function update() {

        if (!sprites.length) return

        for (let s in sprites) {

            const sprite = sprites[s];

            sprite.update();

            if (sprite.isDone()) {

                sprites.splice(s, 1);
            }
        }

    }

    function draw(ctx) {

        if (!sprites.length) return;
        
        for (let sprite in sprites) {

            sprites[sprite].draw(ctx);
        }
    }

    //#endregion

    // Exposed methods.
    return {
        add: add,
        draw: draw,
        update: update
    };
}
