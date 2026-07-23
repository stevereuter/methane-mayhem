# subroutines.bas

# write @selectedItemKey to game board convert @drawTo to x,y
writeGameBoardTileSub:
    x=8 + (@drawTo - INT(@drawTo / 8) * 8) * 3
    y=2 + INT(@drawTo / 8) * 3
    @gameBoard(@drawTo) = @itemValues(@selectedItemKey)
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
playerSelectItemHandlerSub:
    # selecting a tool to use
    # TODO: probably better to just update the selected item here than update the sprite based on that index
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
playerMoveHandlerSub:
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
    @drawTo = @currentPlayerPostision
    @clearTo = @drawTo

    if @keyInputAsc <> 13 then placeItemHandlerSkip

    @selectedItemKey = @gameSidebar(@selectedSidebarIndex)
    @selectedItem = @itemValues(@selectedItemKey)
    @previousItem = @gameBoard(@currentPlayerPostision)

    if @selectedSidebarIndex <> . then utilityHandler
    if @selectedItem = @previousItem then feedNextItemHandler
    if @previousItem = @empty then placePipeHandler
    if @previousItem < @growing then placePipeHandler
    if (@previousItem and @growing) = @growing then placePipeHandler

    @printText$ = "blocked"
    gosub writeLogSub
    goto placeItemHandlerSkip

    # pipe handler
    placePipeHandler:
        gosub writeGameBoardTileSub
        @gameBoard(@drawTo) = @selectedItem
        gosub checkPipeConnectionHandlerSub
        feedNextItemHandler:
        gosub nextItemHandlerSub
    goto placeItemHandlerDone

    # utility handler
    utilityHandler:
        if @previousItem = @empty then placeItemHandlerSkip
        if (@selectedItem and @rotate) = @rotate then rotateItemHandler
        if (@selectedItem and @move) = @move then a = 9 : b = 7 : @drawTo = @currentPlayerPostision : gosub moveItemHandler : goto removeGameBoardItemDone
        # destroy item handler
        if (@selectedItem and @destroy) <> @destroy then placeItemHandlerSkip
        if (@previousItem and @selectedItem and @tree) = @tree then gosub removeGameBoardItem : goto removeGameBoardItemDone
        if (@previousItem and @selectedItem and @rock) = @rock then gosub removeGameBoardItem : goto removeGameBoardItemDone
    goto placeItemHandlerSkip

    # if rotate change
    rotateItemHandler:
        if @previousItem >= @growing then placeItemHandlerSkip
        @selectedItemKey = .
        # handle straight pipes
        if @previousItem = @pipeUp + @pipeDown then @selectedItemKey = 2 : goto rotateItemDraw
        if @previousItem = @pipeLeft + @pipeRight then @selectedItemKey = 1 : goto rotateItemDraw

        if (@selectedItem and @pipeLeft) = @pipeLeft then rotateLefthandler
        # handle rotate right
            if @previousItem = 3 then @selectedItemKey = 3
            if @previousItem = 6 then @selectedItemKey = 4
            if @previousItem = 9 then @selectedItemKey = 5
            if @previousItem = 12 then @selectedItemKey = 6
        goto rotateItemDraw

        rotateLefthandler:
            # handle rotate left
            if @previousItem = 3 then @selectedItemKey = 6
            if @previousItem = 6 then @selectedItemKey = 5
            if @previousItem = 9 then @selectedItemKey = 4
            if @previousItem = 12 then @selectedItemKey = 3

        rotateItemDraw:
            @selectedItem = @itemValues(@selectedItemKey)
            @drawTo = @currentPlayerPostision
            @gameBoard(@drawTo) = @selectedItem
            gosub writeGameBoardTileSub
            gosub checkPipeConnectionHandlerSub
    goto removeSideBarItem
    gosub removeGameBoardItem
    removeGameBoardItemDone:

    removeSideBarItem:
        @gameSidebar(@selectedSidebarIndex) = @empty
        @printText$ = @itemTiles$(@empty)
        gosub writeItemSub
        # reset to first item in sidebar
        @keyInput$ = "1"
        gosub playerSelectItemHandlerSub
    
    placeItemHandlerDone:
        if @isGameOver then placeItemHandlerSkip

        # random cow movement
        gosub cowRandomMovementHandlerSub
        # random tree spawn
        gosub treeSpawnHandlerSub

        gosub updateTimerHandlerSub
    placeItemHandlerSkip:
return

moveItemHandler:
    # move cow
    @moved = 0
    c = 0 : @clearTo = @drawTo
    r = int(rnd(1) * 4) + 1
    getNewPositionHandler:
        c = c + 1
        on r goto moveUpLeft, moveUpRight, moveDownLeft, moveDownRight
        # positions 
        moveUpLeft:
            @nextValue = @drawTo - a
            goto tryMoveItemHandler
        moveUpRight:
            @nextValue = @drawTo - b
            goto tryMoveItemHandler
        moveDownLeft:
            @nextValue = @drawTo + b
            goto tryMoveItemHandler
        moveDownRight:
            @nextValue = @drawTo + a
            # fall through

    tryMoveItemHandler:
        if @nextValue < 0 then retryHandler
        if @nextValue >=54 then retryHandler
        @newItem = @gameBoard(@nextValue)
        if @newItem = @empty then moveItemToNewPositionHandler

        retryHandler:
        # can't move
        if c > 4 then @printText$ = "Can't move" : gosub writeLogSub : goto tryMoveItemHandlerSkip
        r = r + 1
        if r > 4 then r = 1
    
        goto getNewPositionHandler
    
    # add the new cow in the new position
    moveItemToNewPositionHandler:
        @gameBoard(@nextValue) = @previousItem
        
        @selectedItemKey = 8
        @clearTo = @drawTo
        @drawTo = @nextValue
        gosub writeGameBoardTileSub
        @drawTo = @clearTo
        gosub removeGameBoardItem
        # moo
        @printText$ = "Moo!" : gosub writeLogSub
        @moved = @nextValue

    tryMoveItemHandlerSkip:
return

removeGameBoardItem:
    @selectedItemKey = @empty
    gosub writeGameBoardTileSub
return

# pipe connection handler
checkPipeConnectionHandlerSub:
    # loop from begining to see if we reach the end
    @requiredConnection = @pipeRight
    @checkIndex = @connectionEndPosition
    @printText$ = "Checking connections..." : gosub writeLogSub
    for i =. to 55
        @checkTile = @gameBoard(@checkIndex)
        
        # check if not connect
        if (@checkTile and @requiredConnection) = . then i = 55 : goto endValidateGameBoardBounds
        # check if complete
        if @checkIndex = @connectionStartPosition then if (@checkTile and @pipeLeft) = @pipeLeft then @isComplete = -1 : i = 55 : goto endValidateGameBoardBounds

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
    if @isComplete then @printText$ = "Connection complete!" : gosub writeLogSub : @isGameOver = -1
return

cowRandomMovementHandlerSub:
    @moved = -1
    for i = . to 56
        @checkTile = @gameBoard(i)
        # skip past last moved to prevent double move
        if i <= @moved then cowRandomMovementHandlerEnd
        if @checkTile <> @cow then cowRandomMovementHandlerEnd
        if rnd(1) > .7 then cowRandomMovementHandlerEnd
        # move cow
        @drawTo = i
        a = 8 : b = 1
        gosub moveItemHandler
        
        cowRandomMovementHandlerEnd:

        if @checkTile = @tree + @growing then gosub growTreeHandlerSub
    next
return

growTreeHandlerSub:
    @drawTo = i
    @gameBoard(@drawTo) = @tree
    @selectedItemKey = 7
    gosub writeGameBoardTileSub
return

treeSpawnHandlerSub:
    if rnd(1) > .9 then treeSpawnHandlerEnd
    # spawn a tree in a random position on the game board
    @drawTo = int(rnd(1) * 56)
    if @gameBoard(@drawTo) <> @empty then treeSpawnHandlerEnd

    @selectedItemKey = 17
    gosub writeGameBoardTileSub
    @printText$="a tree is growing!" : gosub writeLogSub

    treeSpawnHandlerEnd:
return

updateTimerHandlerSub:
    @timer = @timer - 1 : x = 2
    if @timer < 0 then updateTimerLeak
    
    # update time lower
        @printText$ = "   "
        y = 17 - @timer
        goto updateTimerDraw

    updateTimerLeak:
        y = 18 + @timer
        @printText$ = "{rvon}{grn}   {rvof}"
        if @timer = -17 then @isGameOver = -1 : @printText$ = "Time is up!" : gosub writeLogSub

    updateTimerDraw:
        gosub writeTextSub
return

# feed item handler, move item from feeder to sidebar and replace
nextItemHandlerSub:
    @gameSidebar(0) = @nextItemKey
    @printText$ = @itemTiles$(@nextItemKey)
    gosub writeItemSub
    gosub generateNextItemSub
return

generateLevelSub:
    # reset game board
        for i=. to 55
            @gameBoard(i) = @empty
        next

    # TODO: this needs to be based on the level and the obstacles in it
    gosub generateNextItemSub

    # TODO: add to @gameSidebar
        for @selectedSidebarIndex = 1 to 3
            @selectedItemKey = @tempItems(int(rnd(1) * 5))
            @gameSidebar(@selectedSidebarIndex) = @selectedItemKey
            @printText$ = @itemTiles$(@selectedItemKey)
            gosub writeItemSub
        NEXT

    # TODO: temp remove, create random pipe for item sidebar
        @selectedSidebarIndex = .
        @selectedItemKey = INT(rnd(1) * 6) + 1
        @gameSidebar(@selectedSidebarIndex) = @selectedItemKey
        @printText$ = @itemTiles$(@selectedItemKey)
        gosub writeItemSub

    # TODO: temp remove
    # draw tree, cow, and rock in random positions on the board for testing 7-9
    # TODO: add the items without drawing, then loop through the board and draw once everything is complete to prevent flicker and changes
        for @selectedItemKey = 7 to 9
            @drawTo = INT(rnd(1) * 56)
            gosub writeGameBoardTileSub
            @drawTo = INT(rnd(1) * 56)
            gosub writeGameBoardTileSub
            @drawTo = INT(rnd(1) * 56)
            gosub writeGameBoardTileSub
            @drawTo = INT(rnd(1) * 56)
            gosub writeGameBoardTileSub
        next

    # add random start and end positions for the pipe connection
        @connectionStartPosition = INT(rnd(1) * 7) * 8
        @connectionEndPosition = INT(rnd(1) * 7) * 8 + 7
        @selectedItemKey = 13
        @drawTo = @connectionStartPosition
        gosub writeGameBoardTileSub
        @gameBoard(@connectionStartPosition) = .
        @selectedItemKey = 14
        @drawTo = @connectionEndPosition
        gosub writeGameBoardTileSub
        @gameBoard(@connectionEndPosition) = .
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

generateSeedSub:
    if @isChallengeMode then input "enter a number for the challenge mode seed"; @seed
    if @seed = 0 then @seed = int(rnd(.) * -9000)
    if @seed > 0 then @seed = @seed * -1
    @seed = rnd(@seed)
return

drawGameBoardSub:
# light green background
    poke 53281, 13
# brown border
    poke 53280, 9

# draw main game board
    r1$=" {rvon}     {rvof} {rvon}                          {rvof} {91}{92}{93}{94}{95}"
    r2$="       {rvon} {rvof}                        {rvon} {rvof}"
    r3$=" {rvon} {rvof}   {rvon} {rvof} {rvon} {rvof}                        {rvon} {rvof} {rvon} {rvof}{42}{42}{42}{rvon} {rvof}"
    r4$=" {rvon} {rvof}   {rvon} {rvof} {rvon} {rvof}                        {rvon} {rvof} {rvon} {rvof}   {rvon} {rvof}"
    r5$="       {rvon}                          {rvof}"
    r6$="       {rvon}                          {rvof}"
    r7$=" {rvon}     {rvof} {rvon} {rvof}                        {rvon} {rvof} {rvon}     {rvof}"

    print "{clr}{blk}             methane mayhem"
    print r1$

    for i=. to 2
        print r4$
    next
    print r3$
    for i=. to 11
        print r4$
    next
    print r7$
    for i=. to 3
        print r2$
    next

    print r6$;
return

initializeTimerSub:
# fill the timer
    @timer = 0
    @printText$ = "{rvon}{yellow}   {rvof}"
    x = 2
    for y = 17 to 2 step -1
        gosub writeTextSub
        @timer = @timer + 1
    next
return
