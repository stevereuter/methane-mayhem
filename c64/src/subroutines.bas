# subroutines.bas

locateCursorSub:
    poke 211, x
    poke 214, y
    sys 58732
return

# write tx$ to x,y
writeTextSub:
    gosub locateCursorSub
    print tx$;
return

# write to game board convert index (bi) to x,y
writeGameBoardTileSub:
    x=8 + (bi-int(bi/8)*8)*3
    y=2 + int(bi/8)*3
    gosub writeTextSub
return

# write to items sidebar convert location (si selected item) (0,1,2,3) to x,y
writeItemSub:
    x=35
    y=6 + si*3
    gosub writeTextSub
return

# animate selectors
animateSelectorSub:
    # TODO: we may be able to use the game index here if it has no other use
    # pulse color of main sprites
    td=ti-td
    if td<=10 then animateSelectorDone
    pc=pc+1: td=ti
    if pc>5 then pc=0
    poke 53287, ci(pc)
    poke 53288, ci(pc)
    animateSelectorDone:
return

# item selector handler
itemSelectorHandlerSub:
    # selecting a tool to use
    # TODO: probably better to just update the selected item here then update the sprite based on that index
    # TODO: need to add function keys for selecting the items too
    # 49 or 133
    if in$="1" then poke 53251, 98: si=0
    # 50 or 134
    if in$="2" then poke 53251, 122: si=1
    # 51 or 135
    if in$="3" then poke 53251, 146: si=2
    # 52 or 136
    if in$="4" then poke 53251, 170: si=3
return

# board selector handler
boardSelectorHandlerSub:
    # TODO: need to update the board index (bi), probably better to do this first and calculate the new sprite x,y based on that
    # play area positioning, 24x24 cells in an 8x7 grid
    nx=xp
    ny=yp
    # TODO: we should try to wire up the joystick to see if it is responsive enough
    di=0
    if in$="w" then ny=ny-24:di=-8
    if in$="s" then ny=ny+24:di=8
    if in$="a" then nx=nx-24:di=-1
    if in$="d" then nx=nx+24:di=1
    # TODO: need to add the enter key for using/placing the item selected

    if nx<88 then boardSelectorHandlerDone
    if ny<66 then boardSelectorHandlerDone
    if nx>256 then boardSelectorHandlerDone
    if ny>210 then boardSelectorHandlerDone

    bi=bi+di
    xp=nx
    if xp>255 then xr=xp-256
    yp=ny

    # Set X position
    if xp<256 then poke 53248, xp: poke 53264, peek(53264) and 254
    if xp>255 then poke 53248, xr: poke 53264, peek(53264) or 1
    # Set Y position
    poke 53249, yp
    boardSelectorHandlerDone:
return

# place item handler
placeItemHandlerSub:
    if in<>13 then placeItemHandlerDone
    # TODO: need to validate
    if si<>0 then utilityHandler

    # pile hander
    tx$=bt$(it(si))
    gosub writeGameBoardTileSub
    gb(bi)=it(si)
    GOSUB feedItemHandlerSub
    goto placeItemHandlerDone

    # utility handler
    utilityHandler:
    
    
    placeItemHandlerDone:
return

# feed item handler
feedItemHandlerSub:
    it(0)=fd
    tx$=bt$(fd)
    gosub writeItemSub
    fd=int(rnd(.)*6)+1
    gosub writeFeederHandlerSub
RETURN

# write feeder handler
writeFeederHandlerSub:
    x=35:y=2
    tx$=bt$(fd)
    gosub writeTextSub
return
