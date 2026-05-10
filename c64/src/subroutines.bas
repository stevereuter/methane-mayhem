# subroutines.bas

# write @selectedItem to game board convert @currentPlayerPostision to x,y
writeGameBoardTileSub:
    x=8 + (@currentPlayerPostision - INT(@currentPlayerPostision / 8) * 8) * 3
    y=2 + INT(@currentPlayerPostision / 8) * 3
    @gameBoard(@currentPlayerPostision) = @items(@selectedItem)
    gosub locateCursorSub
    print @boardTiles$(@selectedItem);
return

# write to @itemSidebar sidebar, convert location (@itemSidebarIndex selected item) (0,1,2,3) to x,y
writeItemSub:
    x = 35
    y = 6 + @itemSidebarIndex * 3
    gosub writeTextSub
return

# write feeder handler, select random item and write to feeder area
writeFeederHandlerSub:
    @nextItemFeeder = INT(RND(.) * 6) + 1
    x = 35 : y = 2
    @printText$ = @boardTiles$(@nextItemFeeder)
    gosub writeTextSub
return

# write @printText$ to x,y
writeTextSub:
    gosub locateCursorSub
    print @printText$;
return

# set cursor position to x,y
locateCursorSub:
    poke 211, x
    poke 214, y
    sys 58732
return

# animate selectors
animateSelectorSub:
    # TODO: we may be able to use the game index here if it has no other use
    # pulse color of main sprites
    @timeDifference= TI - @timeDifference
    if @timeDifference <= 10 then animateSelectorDone
    @colorPulsePointer = @colorPulsePointer + 1
    @timeDifference = TI
    if @colorPulsePointer > 5 then @colorPulsePointer = 0
    poke 53287, @colorPulse(@colorPulsePointer)
    poke 53288, @colorPulse(@colorPulsePointer)
    animateSelectorDone:
return

# item selector handler
itemSelectorHandlerSub:
    # selecting a tool to use
    # TODO: probably better to just update the selected item here then update the sprite based on that index
    # TODO: need to add function keys for selecting the @itemSidebar too
    # 49 or 133
    if @keyInput$ = "1" then poke 53251, 98 : @itemSidebarIndex = 0
    # 50 or 134
    if @keyInput$ = "2" then poke 53251, 122 : @itemSidebarIndex = 1
    # 51 or 135
    if @keyInput$ = "3" then poke 53251, 146 : @itemSidebarIndex = 2
    # 52 or 136
    if @keyInput$ = "4" then poke 53251, 170 : @itemSidebarIndex = 3
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
    @currentPlayerPostision = @currentPlayerPostision + @direction
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
    gosub clearLogSub

    if @keyInputAsc <> 13 then placeItemHandlerDone
    if @itemSidebarIndex <> . then utilityHandler

    @selectedItem = @itemSidebar(@itemSidebarIndex)
    @previousItem = @gameBoard(@currentPlayerPostision)

    if @selectedItem = @previousItem then feedNextItemHandler
    if @previousItem = @empty then placePipeHandler
    if @previousItem < @cow then placePipeHandler

    @printText$ = "blocked"
    gosub writeLogSub
    goto placeItemHandlerDone

    # pipe handler
    placePipeHandler:
    gosub writeGameBoardTileSub
    gosub pipeConnectionHandlerSub
    @gameBoard(@currentPlayerPostision) = @selectedItem
    feedNextItemHandler:
    gosub feedItemHandlerSub
    goto placeItemHandlerDone

    # utility handler
    utilityHandler:
    # if axe remove tree
    # if giddy up move cow
    # if blocked add
    
    # empty the item sidebar slot
    
    placeItemHandlerDone:
return

# pipe connection handler using @selectedItem and @previousItem
pipeConnectionHandlerSub:
    @printText$ = "Checking connections..." : gosub writeLogSub
    # loop from begining to see if we reach the end
    @requiredConnection = @pipeLeft
    @checkIndex = @connectionStartPosition
    # FIXME: this loop is not working and always exits after the first check
    for i =. to 55
        m = i
        @checkTile = @gameBoard(@checkIndex)
        # check if not connect
        if (@checkTile and @requiredConnection) = . then i = 55 : goto pipeConnectionHandlerSubEndLoop
        # get next required connection
        if (@checkTile and @pipeUp) = @pipeUp then if (@requiredConnection and @pipeUp) = . then @requiredConnection = @pipeUp : @checkIndex = @checkIndex - 8
        if (@checkTile and @pipeDown) = @pipeDown then if (@requiredConnection and @pipeDown) = . then @requiredConnection = @pipeDown : @checkIndex = @checkIndex + 8
        if (@checkTile and @pipeLeft) = @pipeLeft then if (@requiredConnection and @pipeLeft) = . then @requiredConnection = @pipeLeft : @checkIndex = @checkIndex - 1
        if (@checkTile and @pipeRight) = @pipeRight then if (@requiredConnection and @pipeRight) = . then @requiredConnection = @pipeRight : @checkIndex = @checkIndex + 1
        # check if complete
        if i = @connectionEndPosition then if @requiredConnection = @pipeRight then @isComplete = -1 : i = 55

        pipeConnectionHandlerSubEndLoop:
    next
    @printText$ = "Not complete" + str$(m)
    if @isComplete then @printText$ = "Connection complete!"
    gosub writeLogSub
return

# feed item handler, move item from feeder to sidebar and replace
feedItemHandlerSub:
    @itemSidebar(0) = @nextItemFeeder
    @printText$ = @boardTiles$(@nextItemFeeder)
    gosub writeItemSub
    gosub writeFeederHandlerSub
return

writeLogSub:
    gosub clearLogSub
    gosub locateCursorSub
    print @printText$;
return

clearLogSub:
    x=7 : y=24 : gosub locateCursorSub
    print "{black}                          ";
return
