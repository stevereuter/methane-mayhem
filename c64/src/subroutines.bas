# subroutines.bas

locateCursorSub:
    poke 211, x
    poke 214, y
    sys 58732
return

# write @printText$ to x,y
writeTextSub:
    gosub locateCursorSub
    print @printText$;
return

# write to game board convert index (@boardIndex) to x,y
writeGameBoardTileSub:
    x=8 + (@boardIndex - INT(@boardIndex / 8) * 8) * 3
    y=2 + INT(@boardIndex / 8) * 3
    gosub writeTextSub
return

# animate selectors
animateSelectorSub:
    # TODO: we may be able to use the game index here if it has no other use
    # pulse color of main sprites
    @timeDifference= TI - @timeDifference
    if @timeDifference <= 10 then animateSelectorDone
    @colorPulsePointer = @colorPulsePointer + 1 : @timeDifference = TI
    if @colorPulsePointer > 5 then @colorPulsePointer = 0
    poke 53287, @colorPulse(@colorPulsePointer)
    poke 53288, @colorPulse(@colorPulsePointer)
    animateSelectorDone:
return

# item selector handler
itemSelectorHandlerSub:
    # selecting a tool to use
    # TODO: probably better to just update the selected item here then update the sprite based on that index
    # TODO: need to add function keys for selecting the @items too
    # 49 or 133
    if @keyInput$ = "1" then poke 53251, 98 : @selectedItemIndex = 0
    # 50 or 134
    if @keyInput$ = "2" then poke 53251, 122 : @selectedItemIndex = 1
    # 51 or 135
    if @keyInput$ = "3" then poke 53251, 146 : @selectedItemIndex = 2
    # 52 or 136
    if @keyInput$ = "4" then poke 53251, 170 : @selectedItemIndex = 3
return

# board selector handler
boardSelectorHandlerSub:
    # play area positioning, 24x24 cells in an 8x7 grid
    @newPositionX = @positionX
    @newPositionY = @positionY
    # TODO: we should try to wire up the joystick to see if it is responsive enough
    # direction
    @direction = 0
    if @keyInput$ = "w" then @newPositionY = @newPositionY - 24 : @direction = -8
    if @keyInput$ = "s" then @newPositionY = @newPositionY + 24 : @direction = 8
    if @keyInput$ = "a" then @newPositionX = @newPositionX - 24 : @direction = -1
    if @keyInput$ = "d" then @newPositionX = @newPositionX + 24 : @direction = 1

    if @newPositionX < 88 then boardSelectorHandlerDone
    if @newPositionY < 66 then boardSelectorHandlerDone
    if @newPositionX > 256 then boardSelectorHandlerDone
    if @newPositionY > 210 then boardSelectorHandlerDone

    # update board index based on direction
    @boardIndex = @boardIndex + @direction
    @positionX = @newPositionX
    if @positionX > 255 then @sidebarX = @positionX - 256
    @positionY = @newPositionY

    # Set X position
    if @positionX < 256 then poke 53248, @positionX : poke 53264, peek(53264) and 254
    if @positionX > 255 then poke 53248, @sidebarX : poke 53264, peek(53264) or 1
    # Set Y position
    poke 53249, @positionY
    boardSelectorHandlerDone:
return

# place item handler
placeItemHandlerSub:
    if @keyInputAsc <> 13 then placeItemHandlerDone
    # TODO: need to validate
    if @selectedItemIndex <> @empty then utilityHandler

    @selectedItem = @items(@selectedItemIndex)
    @previousItem = @gameBoard(@boardIndex)

    # pile hander
    @printText$ = @boardTiles$(@selectedItem)
    gosub writeGameBoardTileSub
    @gameBoard(@boardIndex) = @selectedItem
    gosub feedItemHandlerSub
    gosub pipeConnectionHandlerSub

    goto placeItemHandlerDone

    # utility handler
    utilityHandler:
    
    
    placeItemHandlerDone:
return

# pipe connection handler using @selectedItem and @previousItem
pipeConnectionHandlerSub:
    # TODO: add all of the logic for testing the newly added pipe
    # TODO: need to define variables to use for current, existing, start, and end
    # if pipe is replace the same pipe, exit
    if @selectedItem = @previousItem then pipeConnectionHandlerEnd
    # if not connecting exit
    # if connected to end, connect and set as end
    # if replacing end and still connected, set as connected
    # if replacing end and not connected, set end to the pipe that was originally connected
    # if replacing connected one that isn't the end
    # - go to the end and loop backward un-connecting until we get to un-connected pipe (this one)
    # - if connected, set as connected and end
    # - else, set end to the pipe that was originally connected

    # if is end but is also connecter to another pipe, loop up to find the new end
    # if pipe is connected, check if it is connected to the end, winning condition
    pipeConnectionHandlerEnd:
return

# feed item handler, move item from feeder to sidebar and replace
feedItemHandlerSub:
    @items(0) = @nextItemFeeder
    @printText$ = @boardTiles$(@nextItemFeeder)
    gosub writeItemSub
    gosub writeFeederHandlerSub
return

# write to @items sidebar, convert location (@selectedItemIndex selected item) (0,1,2,3) to x,y
writeItemSub:
    x = 35
    y = 6 + @selectedItemIndex * 3
    gosub writeTextSub
return

# write feeder handler, select random item and write to feeder area
writeFeederHandlerSub:
    @nextItemFeeder = INT(RND(.) * 6) + 1
    x = 35 : y = 2
    @printText$ = @boardTiles$(@nextItemFeeder)
    gosub writeTextSub
return
