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

# write to game board convert index (boardIndex) to x,y
writeGameBoardTileSub:
    x=8 + (boardIndex-int(boardIndex/8)*8)*3
    y=2 + int(boardIndex/8)*3
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
    if in$="1" then poke 53251, 98: selectedItem=0
    # 50 or 134
    if in$="2" then poke 53251, 122: selectedItem=1
    # 51 or 135
    if in$="3" then poke 53251, 146: selectedItem=2
    # 52 or 136
    if in$="4" then poke 53251, 170: selectedItem=3
return

# board selector handler
boardSelectorHandlerSub:
    # play area positioning, 24x24 cells in an 8x7 grid
    nx=xp
    ny=yp
    # TODO: we should try to wire up the joystick to see if it is responsive enough
    # direction
    direction=0
    if in$="w" then ny=ny-24:direction=-8
    if in$="s" then ny=ny+24:direction=8
    if in$="a" then nx=nx-24:direction=-1
    if in$="d" then nx=nx+24:direction=1

    if nx<88 then boardSelectorHandlerDone
    if ny<66 then boardSelectorHandlerDone
    if nx>256 then boardSelectorHandlerDone
    if ny>210 then boardSelectorHandlerDone

    # update board index based on direction
    boardIndex=boardIndex+direction
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
    if selectedItem<>0 then utilityHandler

    # pile hander
    tx$=boardTiles$(items(selectedItem))
    gosub writeGameBoardTileSub
    gameBoard(boardIndex)=items(selectedItem)
    gosub feedItemHandlerSub
    goto placeItemHandlerDone

    # utility handler
    utilityHandler:
    
    
    placeItemHandlerDone:
return

# pipe connection handler
pipeConnectionHandlerSub:
    # TODO: add all of the logic for testing the newly added pipe
    # TODO: need to define variables to use for current, existing, start, and end
    # if not connecting exit
    # if pipe is replace the same pipe, exit
    # if connected to end, connect and set as end
    # if replacing end and still connected, set as connected
    # if replacing end and not connected, set end to the pipe that was originally connected
    # if replacing connected one that isn't the end
    # - go to the end and loop backward un-connecting until we get to un-connected pipe (this one)
    # - if connected, set as connected and end
    # - else, set end to the pipe that was originally connected

    # if is end but is also connecter to another pipe, loop up to find the new end
    # if pipe is connected, check if it is connected to the end, winning condition
return

# feed item handler, move item from feeder to sidebar and replace
feedItemHandlerSub:
    items(0)=nextItemFeeder
    tx$=boardTiles$(nextItemFeeder)
    gosub writeItemSub
    gosub writeFeederHandlerSub
return

# write to items sidebar, convert location (selectedItem selected item) (0,1,2,3) to x,y
writeItemSub:
    x=35
    y=6 + selectedItem*3
    gosub writeTextSub
return

# write feeder handler, select random item and write to feeder area
writeFeederHandlerSub:
    nextItemFeeder=int(rnd(.)*6)+1
    x=35:y=2
    tx$=boardTiles$(nextItemFeeder)
    gosub writeTextSub
return
