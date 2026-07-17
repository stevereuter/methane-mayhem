# subroutines.bas

# write @selectedItemKey to game board convert @currentPlayerPostision to x,y
writeGameBoardTileSub:
    x=8 + (@currentPlayerPostision - INT(@currentPlayerPostision / 8) * 8) * 3
    y=2 + INT(@currentPlayerPostision / 8) * 3
    @gameBoard(@currentPlayerPostision) = @itemValues(@selectedItemKey)
    gosub locateCursorSub
    # FIXME: need the item index here not the item value
    print @itemTiles$(@selectedItemKey);
return

# write to @gameSidebar sidebar, convert location (@selectedSidebarIndex selected item) (0,1,2,3) to x,y
writeItemSub:
    x = 35
    y = 6 + @selectedSidebarIndex * 3
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
    # TODO: need to add function keys for selecting the @gameSidebar too
    # 49 or 133
    if @keyInput$ = "1" then poke 53251, 98 : @selectedSidebarIndex = 0
    # 50 or 134
    if @keyInput$ = "2" then poke 53251, 122 : @selectedSidebarIndex = 1
    # 51 or 135
    if @keyInput$ = "3" then poke 53251, 146 : @selectedSidebarIndex = 2
    # 52 or 136
    if @keyInput$ = "4" then poke 53251, 170 : @selectedSidebarIndex = 3
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

    if @keyInputAsc <> 13 then placeItemHandlerSkip

    @selectedItemKey = @gameSidebar(@selectedSidebarIndex)
    @selectedItem = @itemValues(@selectedItemKey)
    @previousItem = @gameBoard(@currentPlayerPostision)

    if @selectedSidebarIndex <> . then utilityHandler
    if @selectedItem = @previousItem then feedNextItemHandler
    if @previousItem = @empty then placePipeHandler
    if @previousItem < @cow then placePipeHandler

    @printText$ = "blocked"
    gosub writeLogSub
    goto placeItemHandlerSkip

    # pipe handler
    placePipeHandler:
    gosub writeGameBoardTileSub
    @gameBoard(@currentPlayerPostision) = @selectedItem
    gosub pipeConnectionHandlerSub
    feedNextItemHandler:
    gosub nextItemHandlerSub
    goto placeItemHandlerDone

    # utility handler
    utilityHandler:
    if @previousItem = @empty then placeItemHandlerSkip
    if (@selectedItem and @rotate) = @rotate then rotateItemHandler
    if (@selectedItem and @move) = @move then moveItemHandler
    # destroy item handler
    # TODO: fix destroy item issues, cutting tree on empty adds cow
    if (@previousItem and @selectedItem and @tree) = @tree then removeGameBoardItem
    if (@previousItem and @selectedItem and @rock) = @rock then removeGameBoardItem

    moveItemHandler:
    # TODO: fix move
    # if giddy up move cow
    i = 0
    r = int(rnd(1) * 4) + 1
    getNewPositionHandler:
    i = i + 1
    on r goto moveUpLeft, moveUpRight, moveDownLeft, moveDownRight
    # positions 
    moveUpLeft:
    r = @currentPlayerPostision - 9
    goto tryMoveItemHandler
    moveUpRight:
    r = @currentPlayerPostision - 7
    goto tryMoveItemHandler
    moveDownLeft:
    r = @currentPlayerPostision + 7
    goto tryMoveItemHandler
    moveDownRight:
    r = @currentPlayerPostision + 9
    # fall through
    tryMoveItemHandler:
    @newItem = @gameBoard(r)
    if (@newItem and @empty) = @empty then moveItemToNewPositionHandler

    retryHandler:
    # can't move
    if i > 4 then @printText$ = "Can't move" : gosub writeLogSub : goto placeItemHandlerDone
    r = r + 1
    if r > 4 then r = 1
    goto getNewPositionHandler
    # add the new cow in the new position
    moveItemToNewPositionHandler:
    @gameBoard(r) = @previousItem
    
    @selectedItemKey = 8
    i = @currentPlayerPostision
    @currentPlayerPostision = r
    gosub writeGameBoardTileSub
    @currentPlayerPostision = i

    goto removeGameBoardItem

    # if rotate change
    rotateItemHandler:
    @selectedItemKey = .
    # handle straight pipes
    if @previousItem = @pipeUp + @pipeDown then @selectedItemKey = 2
    if @previousItem = @pipeLeft + @pipeRight then @selectedItemKey = 1
    if @selectedItemKey > . then rotateItemDraw

    if @selectedItem = @pipeLeft then rotateLefthandler
    # TODO: fix rotate issues
    # handle rotate right
    if @previousItem = 3 then @selectedItemKey = 3
    if @previousItem = 6 then @selectedItemKey = 4
    if @previousItem = 12 then @selectedItemKey = 6
    if @previousItem = 9 then @selectedItemKey = 5
    goto rotateItemDraw
    rotateLefthandler:
    # handle rotate left
    if @previousItem = 3 then @selectedItemKey = 5
    if @previousItem = 9 then @selectedItemKey = 6
    if @previousItem = 12 then @selectedItemKey = 4
    if @previousItem = 6 then @selectedItemKey = 3

    rotateItemDraw:
    @selectedItem = @itemValues(@selectedItemKey)
    @gameBoard(@currentPlayerPostision) = @selectedItem
    gosub writeGameBoardTileSub
    gosub pipeConnectionHandlerSub
    goto removeSideBarItem

    removeGameBoardItem:
    @selectedItemKey = @empty
    gosub writeGameBoardTileSub

    removeSideBarItem:
    @gameSidebar(@selectedSidebarIndex) = @empty
    @printText$ = @itemTiles$(@empty)
    gosub writeItemSub
    # reset to first item in sidebar
    @keyInput$ = "1"
    gosub itemSelectorHandlerSub
    
    placeItemHandlerDone:
        # random cow movement
    gosub movementActionHandlerSub

    placeItemHandlerSkip:
return

# pipe connection handler
pipeConnectionHandlerSub:
    # loop from begining to see if we reach the end
    @requiredConnection = @pipeLeft
    @checkIndex = @connectionStartPosition
    @printText$ = "Checking connections..." : gosub writeLogSub
    for i =. to 55
        @checkTile = @gameBoard(@checkIndex)
        
        # check if not connect
        if (@checkTile and @requiredConnection) = . then i = 55 : goto endValidateGameBoardBounds
        # check if complete
        if @checkIndex = @connectionEndPosition then if (@checkTile and @pipeRight) = @pipeRight then @isComplete = -1 : i = 55 : goto endValidateGameBoardBounds

        # get next required connection
        if (@checkTile and @pipeUp) = @pipeUp then if (@requiredConnection and @pipeUp) = . then @requiredConnection = @pipeDown : @nextIndex = @checkIndex - 8 : goto validateGameBoardBounds
        if (@checkTile and @pipeDown) = @pipeDown then if (@requiredConnection and @pipeDown) = . then @requiredConnection = @pipeUp : @nextIndex = @checkIndex + 8 : goto validateGameBoardBounds
        if (@checkTile and @pipeLeft) = @pipeLeft then if (@requiredConnection and @pipeLeft) = . then @requiredConnection = @pipeRight : @nextIndex = @checkIndex - 1 : goto validateGameBoardBounds
        if (@checkTile and @pipeRight) = @pipeRight then if (@requiredConnection and @pipeRight) = . then @requiredConnection = @pipeLeft : @nextIndex = @checkIndex + 1

        validateGameBoardBounds:
        if @nextIndex < 0 then i = 55 : goto endValidateGameBoardBounds
        if @nextIndex > 55 then i = 55 : goto endValidateGameBoardBounds
        @column = @checkIndex - INT(@checkIndex / 8) * 8
        if @column = 0 then if @nextIndex = @checkIndex - 1 then i = 55 : goto endValidateGameBoardBounds
        if @column = 7 then if @nextIndex = @checkIndex + 1 then i = 55 : goto endValidateGameBoardBounds

        @checkIndex = @nextIndex
        endValidateGameBoardBounds:
    next
    gosub clearLogSub
    if @isComplete then @printText$ = "Connection complete!" : gosub writeLogSub
return

movementActionHandlerSub:
    for i = . to 56
        @checkTile = @gameBoard(i)
        if @checkTile <> @cow then movementActionHandlerEnd
        # TODO: get random direction and move if empty
        r = int(rnd(1) * 10) + 1
        on r goto noCowMove, cowMoveUp, cowMoveRight, cowMoveDown, cowMoveLeft
        noCowMove:
            r = i
            goto movementActionHandlerEnd
        cowMoveUp:
            r = i - 8
            goto cowMoveHandler
        cowMoveRight:
            r = i + 1
            goto cowMoveHandler
        cowMoveDown:
            r = i + 8
            goto cowMoveHandler
        cowMoveLeft:
            r = i - 1
            goto cowMoveHandler

        cowMoveHandler:
        if r < 0 then movementActionHandlerEnd
        if r > 55 then movementActionHandlerEnd
        if @gameBoard(r) <> @empty then movementActionHandlerEnd
        # move cow to r
        # clear i

        # moo
        @printText$ = "Moo!" : gosub writeLogSub
        
        movementActionHandlerEnd:
    next

return

# feed item handler, move item from feeder to sidebar and replace
nextItemHandlerSub:
    @gameSidebar(0) = @nextItemKey
    @printText$ = @itemTiles$(@nextItemKey)
    gosub writeItemSub
    gosub generateNextItemSub
return

# write feeder handler, select random item and write to feeder area
generateNextItemSub:
    i = len(@feeder$)
    if i < 1 then gosub fillFeederSub : i = len(@feeder$)
    r = int(rnd(1) * i) + 1
    @nextItemKey = val(mid$(@feeder$, r , 1))
    @feeder$ = left$(@feeder$, r - 1) + mid$(@feeder$, r + 1)
    x = 35 : y = 2
    @printText$ = @itemTiles$(@nextItemKey)
    gosub writeTextSub
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

fillFeederSub:
    for c = 1 to 6
        for i = . to 1
            @feeder$ = @feeder$ + right$(str$(c), 1)
        next
    next
return
