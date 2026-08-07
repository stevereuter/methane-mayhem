# subroutines.bas

# write @selectedItemKey to game board convert @drawTo to x,y
writeGameBoardTileSub:
    gosub boardIndexToCharacterXYSub
    @gameBoard(@drawTo) = @itemValues(@selectedItemKey)
    gosub locateCursorSub
    print @itemTiles$(@selectedItemKey);
return

# convert board index to x,y coordinates
boardIndexToCharacterXYSub:
    x=8 + (@drawTo - int(@drawTo / 8) * 8) * 3
    y=2 + int(@drawTo / 8) * 3
return

# set sprite position for @currentSprite at @drawTo
setSpritePositionSub:
    gosub boardIndexToCharacterXYSub
    x = 24 + x * 8
    if x < 256 then poke @spriteScreenRight, peek(@spriteScreenRight) and not (2 ^ @currentSprite)
    if x > 255 then x = x - 255 : poke @spriteScreenRight, peek(@spriteScreenRight) or (2 ^ @currentSprite)
    poke @spriteRegX + @currentSprite * 2, x
    poke @spriteRegY + @currentSprite * 2, 48 + y * 8
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
    poke @spriteColor + 1, @colorPulse(@colorPulsePointer)
    poke @spriteColor + 2, @colorPulse(@colorPulsePointer)
    animateSelectorDone:
return

# item selector handler
playerSelectItemHandlerSub:
    # selecting a tool to use
    # TODO: need to add function keys for selecting the @gameSidebar too
    # 49 or 133
    if @keyInput$ = "1" then poke @spriteRegY + 4, 98 : @selectedSidebarIndex = 0
    # 50 or 134
    if @keyInput$ = "2" then poke @spriteRegY + 4, 122 : @selectedSidebarIndex = 1
    # 51 or 135
    if @keyInput$ = "3" then poke @spriteRegY + 4, 146 : @selectedSidebarIndex = 2
    # 52 or 136
    if @keyInput$ = "4" then poke @spriteRegY + 4, 170 : @selectedSidebarIndex = 3
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
    if @positionX < 256 then poke @spriteRegX + 2, @positionX : poke @spriteScreenRight, peek(@spriteScreenRight) and 253
    if @positionX > 255 then poke @spriteRegX + 2, @sidebarX : poke @spriteScreenRight, peek(@spriteScreenRight) or 2
    # Set Y position
    poke @spriteRegY + 2, @positionY
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
        if fn @checkGameState(@gameStateComplete) then placeItemHandlerSkip
        feedNextItemHandler:
        gosub nextItemHandlerSub
        goto placeItemHandlerDone

    # utility handler
    utilityHandler:
        if @previousItem = @empty then placeItemHandlerSkip
        if (@selectedItem and @rotate) = @rotate then rotateItemHandler
        if (@selectedItem and @move) = @move then a = 9 : b = 7 : @drawTo = @currentPlayerPostision : gosub moveCowSub : goto removeGameBoardItemDone
        # fire and explotions
        if (@selectedItem and @cow) = @cow then placeItemHandlerSkip
        if (@selectedItem and @burning) = @burning then if (@previousItem and @tree) = @tree then gosub addFireToBoardSub : goto removeGameBoardItemDone
        if (@selectedItem and @explosion) = @explosion then gosub addExplosionToBoardSub : goto removeGameBoardItemDone
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
            if fn @checkGameState(@gameStateComplete) then placeItemHandlerSkip
        goto removeSideBarItem

    removeGameBoardItemDone:

    removeSideBarItem:
        @gameSidebar(@selectedSidebarIndex) = @empty
        @printText$ = @itemTiles$(@empty)
        gosub writeItemSub
        # reset to first item in sidebar
        @keyInput$ = "1"
        gosub playerSelectItemHandlerSub
        @toolCount = @toolCount - 1
        if @toolCount < 1 then gosub replenishToolsSub
    
    placeItemHandlerDone:

    if fn @checkGameState(@gameStateOver) then placeItemHandlerSkip

    # random cow movement
    gosub randomGameEventsHandlerSub
    # end panic chance
    gosub endPanicHandlerSub
    # random tree spawn
    gosub treeSpawnHandlerSub
    # catastrophic events
    # alien invasion, add alien cow
    if fn @checkGameState(@gameStateAlienInvasion) then gosub alienInvasionHandlerSub
    # UFO abduction, remove cow
    if fn @checkGameState(@gameStateUfoAbduction) then gosub ufoAbductionHandlerSub
    # meteor strike
    if fn @checkGameState(@gameStateMeteor) then gosub meteorStrikeHandlerSub

    gosub catastrophicEventHandlerSub

    gosub updateTimerHandlerSub

    placeItemHandlerSkip:
return

moveCowSub:
    # move cow
    @moved = -1
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
        if (@previousItem and @invincible) = @invincible then moveItemToNewPositionHandler
        @newItem = @gameBoard(@nextValue)
        if @newItem = @empty then moveItemToNewPositionHandler

    retryHandler:
        # can't move
        if c > 4 then goto tryMoveItemHandlerSkip
        r = r + 1
        if r > 4 then r = 1
        goto getNewPositionHandler
    
    # add the new cow in the new position
    moveItemToNewPositionHandler:
        if (@newItem and @cow) = @cow then @gameState = fn @addGameState(@gameStateAlienInvasion)
        c = 8 : if (@previousItem and @invincible) = @invincible then c = 20
        @selectedItemKey = c
        @clearTo = @drawTo
        @drawTo = @nextValue
        gosub writeGameBoardTileSub
        @drawTo = @clearTo
        gosub removeGameBoardItem
        # moo
        @printText$ = "Moo!" : gosub writeLogSub
        @moved = @nextValue

    tryMoveItemHandlerSkip:
    if @moved = 0 then if a = 9 then @printText$ = "Can't move" : gosub writeLogSub
return

addFireToBoardSub:
    @gameBoard(@currentPlayerPostision) = @previousItem + @burning

    gosub boardIndexToCharacterXYSub
    c = 2
    for a=y to y+2
        if a = y+2 then c = 10
        for b=x to x+2
            poke 55296 + b + (a * 40), c
        next
    next
    # set sprite position
    @currentSprite = 7
    gosub setSpritePositionSub
    # enable sprite
    poke @spritesEnabled, peek(@spritesEnabled) or 128
    poke @spriteReg + @currentSprite, @spriteFire
    @burnAnimation = 1
    @printText$ = "cows are panicing" : gosub writeLogSub
    @gameState = fn @addGameState(@gameStatePanicing)

    addFireToBoardEnd:
return

addExplosionToBoardSub:
    @column = @currentPlayerPostision - int(@currentPlayerPostision / 8) * 8
    @explosionPositions(0) = @currentPlayerPostision
    @explosionPositions(1) = @currentPlayerPostision - 8
    @explosionPositions(2) = @currentPlayerPostision + 8
    @explosionPositions(3) = -1
    @explosionPositions(4) = -1
    if @column > 0 then @explosionPositions(3) = @currentPlayerPostision - 1
    if @column < 7 then @explosionPositions(4) = @currentPlayerPostision + 1
    
    for i=. to 4
        if @explosionPositions(i) < 0 then addExplosionToBoardLoopEnd
        if @explosionPositions(i) > 55 then addExplosionToBoardLoopEnd

        @drawTo = @explosionPositions(i)
        gosub removeGameBoardItem

        addExplosionToBoardLoopEnd:
    next

    @printText$ = "cows are panicking" : gosub writeLogSub
    @gameState = fn @addGameState(@gameStatePanicing)
    
return

removeGameBoardItem:
    @selectedItemKey = @empty
    gosub writeGameBoardTileSub
return

# pipe connection handler
checkPipeConnectionHandlerSub:
    # loop from begining to see if we reach the end
    @requiredConnection = @pipeLeft
    @checkIndex = @connectionStartPosition
    @printText$ = "Checking connections..." : gosub writeLogSub
    for i =. to 55
        @checkTile = @gameBoard(@checkIndex)
        
        # check if not connect
        if (@checkTile and @requiredConnection) = . then i = 55 : goto endValidateGameBoardBounds
        # check if complete
        if @checkIndex = @connectionEndPosition then if (@checkTile and @pipeRight) = @pipeRight then @gameState = fn @addGameState(@gameStateComplete) : i = 55 : goto endValidateGameBoardBounds

        # get next required connection
        if (@checkTile and @pipeUp) = @pipeUp then if (@requiredConnection and @pipeUp) = . then @requiredConnection = @pipeDown : @nextIndex = @checkIndex - 8 : goto validateGameBoardBounds
        if (@checkTile and @pipeDown) = @pipeDown then if (@requiredConnection and @pipeDown) = . then @requiredConnection = @pipeUp : @nextIndex = @checkIndex + 8 : goto validateGameBoardBounds
        if (@checkTile and @pipeLeft) = @pipeLeft then if (@requiredConnection and @pipeLeft) = . then @requiredConnection = @pipeRight : @nextIndex = @checkIndex - 1 : goto validateGameBoardBounds
        if (@checkTile and @pipeRight) = @pipeRight then if (@requiredConnection and @pipeRight) = . then @requiredConnection = @pipeLeft : @nextIndex = @checkIndex + 1

        validateGameBoardBounds:
            if @nextIndex < 0 then i = 55 : goto endValidateGameBoardBounds
            if @nextIndex > 55 then i = 55 : goto endValidateGameBoardBounds
            @column = @checkIndex - int(@checkIndex / 8) * 8
            if @column = 0 then if @nextIndex = @checkIndex - 1 then i = 55 : goto endValidateGameBoardBounds
            if @column = 7 then if @nextIndex = @checkIndex + 1 then i = 55 : goto endValidateGameBoardBounds

        @checkIndex = @nextIndex
        endValidateGameBoardBounds:
        # TODO: check if leaking and move animation to @checkIndex
    next
    gosub clearLogSub

    if fn @checkGameState(@gameStateComplete) then @printText$ = "connection complete!" : gosub writeLogSub
return

randomGameEventsHandlerSub:
    @moved = -1
    a = 8 : b = 1 : @ufoTarget = -1
    for i = . to 56
        @previousItem = @gameBoard(i)
        # skip past last moved to prevent double move
        if i <= @moved then randomGameEventsHandlerEnd
        if (@previousItem and @cow) <> @cow then randomGameEventsHandlerEnd
        r = .7 : if @getGameState(@gameStatePanicing) then r = 0
        if rnd(1) > r then randomGameEventsHandlerEnd
        # move cow
        @drawTo = i
        gosub moveCowSub
        
        randomGameEventsHandlerEnd:

        @drawTo = i
        # grow trees
        if @previousItem = @tree + @growing then gosub growTreeHandlerSub
        # remove burning trees
        if @previousItem = @tree + @destroy then poke @spritesEnabled, peek(@spritesEnabled) and not 128 : gosub removeGameBoardItem
        # update burning trees to be destroyed
        if @previousItem = @tree + @burning then @gameBoard(i) = @tree + @destroy
        # if cow and is abduction, set UFO target
        if fn @checkGameState(@gameStateUfoAbduction) then if @previousItem = @cow then @ufoTarget = i
    next
    if fn @checkGameState(@gameStateUfoAbduction) then if @ufoTarget = -1 then @gameState = fn @removeGameState(@gameStateUfoAbduction) : @gameState = fn @addGameState(@gameStateAlienInvasion)
return

growTreeHandlerSub:
    @gameBoard(@drawTo) = @tree
    @selectedItemKey = 7
    # sprite 3
    @currentSprite = 3
    gosub setSpritePositionSub
    # set first frame
    poke @spriteReg + @currentSprite, @spriteTreeGrow
    # set color
    poke @spriteColor + @currentSprite, 5
    # enable
    poke @spritesEnabled, peek(@spritesEnabled) or (2 ^ @currentSprite)
    # pause
    for i = . to 100 : next
    # show second frame
    poke @spriteReg + @currentSprite, @spriteTreeGrow + 1
    # pause
    for i = . to 100 : next
    gosub writeGameBoardTileSub
    # disable
    poke @spritesEnabled, peek(@spritesEnabled) and not (2 ^ @currentSprite)
return

treeSpawnHandlerSub:
    if rnd(1) > .5 then treeSpawnHandlerEnd
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
        if @timer = -17 then @gameState = fn @addGameState(@gameStateOver) : @printText$ = "Time is up!" : gosub writeLogSub

    updateTimerDraw:
        gosub writeTextSub
return

# feed item handler, move item from feeder to sidebar and replace
nextItemHandlerSub:
    @gameSidebar(0) = @nextItemKey
    @printText$ = @itemTiles$(@nextItemKey)
    gosub writeItemSub
    gosub generateNextPipeSub
return

endPanicHandlerSub:
    if @getGameState(@gameStatePanicing) = 0 then endPanicHandlerEnd
    if rnd(1) > .5 then endPanicHandlerEnd

    @gameState = fn @removeGameState(@gameStatePanicing)
    @printText$ = "cows have calmed down" : gosub writeLogSub
    
    endPanicHandlerEnd:
return

# alien invasion handler
alienInvasionHandlerSub:
    # TODO: add alien cow based on abduction game state
    @drawTo = int(rnd(1) * 56)
    @previousItem = @gameBoard(@drawTo)

    # animate UFO to random postions
    # animate beam
    # show alien cow
    @selectedItemKey = 20
    gosub writeGameBoardTileSub
    # remove beam
    # animate UFO away

    if (@previousItem and @cow) <> @cow then @gameState = fn @removeGameState(@gameStateAlienInvasion)
    @printText$ = "alien invasion!" : gosub writeLogSub

    alienInvasionHandlerEnd:
return

# UFO abduction
ufoAbductionHandlerSub:
    # TODO: animate UFO to cow @ufoTarget
    # show beam
    # remove cow
    @drawTo = @ufoTarget
    gosub removeGameBoardItem
    @printText$ = "alien abduction!" : gosub writeLogSub
    # remove beam
    # animate UFO away
    @ufoTarget = -1
    @gameState = fn @removeGameState(@gameStateUfoAbduction)
    @gameState = fn @addGameState(@gameStateAlienInvasion)

    ufoAbductionHandlerEnd:
return

# meteor strike
meteorStrikeHandlerSub:
    c = @currentPlayerPostision
    @currentPlayerPostision = int(rnd(1) * 56)
    @printText$ = "meteor strike! " + str$(@currentPlayerPostision) : gosub writeLogSub
    # TODO: animate sprite, position should be set on the random event loop
    # preform explotion
    gosub addExplosionToBoardSub
    # add rock
    @drawTo = @currentPlayerPostision
    @selectedItemKey = 9
    gosub writeGameBoardTileSub
    # remove sprite
    @currentPlayerPostision = c
    @gameState = fn @removeGameState(@gameStateMeteor)

    meteorStrikeHandlerEnd:
return

catastrophicEventHandlerSub:
    if @level < 7 then catastrophicEventHandlerEnd
    if fn @checkGameState(@gameStateAlienInvasion) then catastrophicEventHandlerEnd
    if rnd(1) < .9 then catastrophicEventHandlerEnd

    c = @gameStateMeteor : if rnd(1) < .5 then c = @gameStateUfoAbduction

    @gameState = fn @addGameState(c)
    @printText$ = "incoming danger!" : gosub writeLogSub

    catastrophicEventHandlerEnd:
return

generateLevelSub:
    # reset game board
    for i=. to 55
        @gameBoard(i) = @empty
    next

    # add pipes and tools to sidebar
    gosub replenishToolsSub
    gosub generateNextPipeSub
    gosub nextItemHandlerSub

    # draw tree, cow, and rock
    c = 3
    if @level < 3 then c = @level + 1
    if @level > 7 then c = 4
    for i = 0 to @level + 6
        @selectedItemKey = @levelItems(int(rnd(1) * c))
        @drawTo = INT(rnd(1) * 56)
        @gameBoard(@drawTo) = @itemValues(@selectedItemKey)
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

    gosub drawBoardItemsSub

    @printText$ = "level " + str$(@level) : gosub writeLogSub
return

# replenish tools
replenishToolsSub:
    c = @level + 3
    if @level > 5 then c = 6
    if @level > 8 then c = 7
    for @selectedSidebarIndex = 3 to 1 step -1
        @selectedItemKey = @levelTools(int(rnd(1) * c))
        if @level > 6 then if @selectedItemKey = 12 then @selectedItemKey = 18
        if @level > 7 then if @selectedItemKey = 11 then @selectedItemKey = 19
        @gameSidebar(@selectedSidebarIndex) = @selectedItemKey
        @printText$ = @itemTiles$(@selectedItemKey)
        gosub writeItemSub
    next
    @toolCount = 3
    @printText$ = "tools replenished" : gosub writeLogSub
return

# draw board item
drawBoardItemsSub:
    for @drawTo = 0 to 55
        c = @gameBoard(@drawTo)

        if c = @empty then drawBoardItemEnd
        if c = @cow + @invincible then @selectedItemKey = 20 : goto drawBoardItemSkip
        if c = @cow then @selectedItemKey = 8 : goto drawBoardItemSkip
        if c = @tree + @growing then @selectedItemKey = 17 : goto drawBoardItemSkip
        if c = @tree then @selectedItemKey = 7 : goto drawBoardItemSkip
        if c = @rock then @selectedItemKey = 9 : goto drawBoardItemSkip

        drawBoardItemSkip:
        gosub writeGameBoardTileSub
        drawBoardItemEnd:
    next
return

# write feeder handler, select random item and write to feeder area
generateNextPipeSub:
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
    if fn @checkGameState(@gameStateChallengeMode) then input "enter a number for the challenge mode seed"; @seed
    if @seed = 0 then @seed = int(rnd(.) * -9000)
    if @seed > 0 then @seed = @seed * -1
    @seed = rnd(@seed)
    if fn @checkGameState(@gameStateChallengeMode) then @level = int(rnd(1) * 10) + 1
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
