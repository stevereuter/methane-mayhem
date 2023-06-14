/** @format */

export function GridObject() {
    //#region Properties.

    const me = this;
    me.type = '';
    me.start = 0;
    me.end = 0;
    me.create = create;
    me.update = update;
    //#endregion

    //#region Methods.

    function resetPipe() {
        me.n = false;
        me.e = false;
        me.s = false;
        me.w = false;
    }

    function changePipe(type) {
        me.type = type;

        if (type.length > 2) return;

        if (type.includes('n')) me.n = true;
        if (type.includes('e')) me.e = true;
        if (type.includes('s')) me.s = true;
        if (type.includes('w')) me.w = true;
    }

    function create(type, start, end) {
        if (start) {
            me.start = start;
        }
        if (end) {
            me.end = end;
        }

        resetPipe();

        changePipe(type);
    }

    function update(start, end, type) {
        if (start >= 0) {
            me.start = start;
        }
        if (end >= 0) {
            me.end = end;
        }
        if (type) {
            changePipe(type);
        }
    }

    //#endregion

    resetPipe();

    // Exposed methods.
    return me;
}
