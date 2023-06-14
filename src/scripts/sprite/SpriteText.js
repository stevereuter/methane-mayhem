/** @format */

export function SpriteText(text, size, color, startX, startY, outline) {
    //#region Properties.

    const font = `${size}px Arial`;
    let x = startX;
    let y = startY;
    let colorRgb =
        typeof color === 'object'
            ? `rgba(${color.r},${color.g},${color.b},1)`
            : undefined;
    let outlineRgb =
        outline && typeof outline === 'object'
            ? `rgba(${outline.r},${outline.g},${outline.b},1)`
            : undefined;

    //#endregion

    //#region Methods.

    function positionX() {
        return x;
    }

    function positionY() {
        return y;
    }

    function update(newX, newY, percent) {
        x = newX;
        y = newY;

        if (colorRgb) {
            colorRgb = `rgba(${color.r},${color.g},${color.b},${percent})`;
        }
        if (outlineRgb) {
            outlineRgb = `rgba(${outline.r},${outline.g},${outline.b},${percent})`;
        }
    }

    function draw(ctx) {
        ctx.font = font;
        const textWidth = ctx.measureText(text).width;

        ctx.fillStyle = colorRgb ? colorRgb : color;
        ctx.strokeStyle = outlineRgb ? outlineRgb : outline;

        ctx.fillText(text, x - textWidth / 2, y);
        ctx.strokeText(text, x - textWidth / 2, y);
    }

    //#endregion

    // Exposed methods.
    return {
        draw: draw,
        update: update,
        x: positionX,
        y: positionY,
    };
}
