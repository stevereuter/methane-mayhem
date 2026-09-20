# ---------------------> main loop subs
# animate selectors
joystickInputHandlerSub:
    @joystickInput = peek(@port2Register)

    @joystickIdle = (@joystickInput and 31) = 31
    if @joystickIdle then goto joystickInputHandlerEnd
    @fireOn = (@joystickInput and 16) = 0
    @directionUp = (@joystickInput and 1) = 0
    @directionDown = (@joystickInput and 2) = 0
    @directionLeft = (@joystickInput and 4) = 0
    @directionRight = (@joystickInput and 8) = 0

    joystickInputHandlerEnd:
return

mainLoopAnimationSub:
    # pulse color of main sprites
    @colorPulsePointer = @colorPulsePointer + 1
    if @colorPulsePointer > 5 then @colorPulsePointer = 0
    poke @spriteColor + 2 + not @isSidebar, @colorPulse(@colorPulsePointer)

    poke @spriteReg + 6, @spriteGas + @twoFrameAnimation
    poke @spriteReg + 7, @spriteFire + @twoFrameAnimation
    @twoFrameAnimation = 1 - @twoFrameAnimation
return

# item selector handler
playerSelectItemHandlerSub:
    # selecting a tool to use
    if @directionLeft then @isSidebar = . : goto playerSelectItemHandlerEnd

    c = @selectedSidebarIndex
    if @directionUp then c = c - 1
    if @directionDown then c = c + 1
    if c < 0 then c = 3
    if c > 3 then c = 0
    if @selectedSidebarIndex = c then playerSelectItemHandlerEnd

    @selectedSidebarIndex = c

    gosub setToolSelectorPositionSub
    # update the play sprite here
    gosub setSelectorFrameSub
    playerSelectItemHandlerEnd:
return

# board selector handler
playerMoveHandlerSub:
    # play area positioning, 24x24 cells in an 8x7 grid
    # direction
    @drawTo = @currentPlayerPosition
    c = fn @getColumn(@currentPlayerPosition)
    if c = 7 then if @directionRight then @isSidebar = -1 : goto boardSelectorHandlerDone
    if @directionUp then @drawTo = @drawTo - 8
    if @directionDown then @drawTo = @drawTo + 8
    if c > 0 then if @directionLeft then @drawTo = @drawTo - 1
    if c < 7 then if @directionRight then @drawTo = @drawTo + 1

    if @drawTo < 0 then boardSelectorHandlerDone
    if @drawTo > 55 then boardSelectorHandlerDone

    # update board index based on direction
    @currentPlayerPosition = @drawTo
    @currentSprite = 1
    gosub setSpritePositionByTileSub

    boardSelectorHandlerDone:
return

# place item handler
placeItemHandlerSub:
    gosub clearLogSub
    @drawTo = @currentPlayerPosition
    @clearTo = @drawTo

    if not @fireOn then placeItemHandlerSkip
    
    @selectedItemKey = @gameSidebar(@selectedSidebarIndex)
    @selectedItem = @itemValues(@selectedItemKey)

    if @selectedItem = @empty then placeItemHandlerSkip

    poke @borderColor, 11
    # turn off selectors
    poke @spritesEnabled, peek(@spritesEnabled) and 121

    @previousItem = @gameBoard(@currentPlayerPosition)

    if @selectedSidebarIndex <> . then utilityHandler
    if @selectedItem = @previousItem then feedNextItemHandler
    if @previousItem = @empty then placePipeHandler
    if @previousItem < @growing then placePipeHandler
    if (@previousItem and @growing) = @growing then placePipeHandler

    
    gosub clearLogSub : print "blocked";
    goto placeItemHandlerSkip

    # pipe handler
    placePipeHandler:
        gosub writeGameBoardTileSub
        @gameBoard(@drawTo) = @selectedItem
        gosub clearLogSub : print "checking connections...";
        gosub checkPipeConnectionHandlerSub
        gosub clearLogSub
        if fn @checkGameState(@gameStateComplete) then placeItemHandlerSkip
        feedNextItemHandler:
        gosub nextItemHandlerSub
        gosub setSelectorFrameSub
        goto placeItemHandlerDone

    # utility handler
    utilityHandler:
        if @previousItem = @empty then placeItemHandlerSkip
        if (@selectedItem and @rotate) = @rotate then rotateItemHandler
        if (@selectedItem and @move) = @move then a = 9 : b = 7 : @drawTo = @currentPlayerPosition : gosub moveCowSub : if @moved > -1 then goto removeGameBoardItemDone : if @moved < 0 then placeItemHandlerDone
        # fire and explotions
        if (@previousItem and @cow) = @cow then placeItemHandlerSkip
        if (@selectedItem and @burning) = @burning then if (@previousItem and @tree) = @tree then gosub addFireToBoardSub : goto removeGameBoardItemDone
        if (@selectedItem and @explosion) = @explosion then if (@previousItem and @rock) = @rock then gosub addExplosionToBoardSub : goto removeGameBoardItemDone
        @animationColor = 1
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
            @drawTo = @currentPlayerPosition
            @gameBoard(@drawTo) = @selectedItem
            gosub writeGameBoardTileSub
            gosub clearLogSub : print "checking connections...";
            gosub checkPipeConnectionHandlerSub
            gosub clearLogSub
            if fn @checkGameState(@gameStateComplete) then placeItemHandlerSkip
        goto removeSideBarItem

    removeGameBoardItemDone:

    removeSideBarItem:
        @gameSidebar(@selectedSidebarIndex) = @empty
        gosub locateItemSub : print @itemTiles$(@empty)
        # reset to first item in sidebar
        @selectedSidebarIndex = 0
        gosub setToolSelectorPositionSub
        gosub setSelectorFrameSub
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
    # leak explosion
    if fn @checkGameState(@gameStateLeakExplosion) then gosub leakExplosionHandlerSub
    # run the connection check sub
    gosub checkPipeConnectionHandlerSub

    gosub catastrophicEventHandlerSub

    gosub updateTimerHandlerSub

    placeItemHandlerSkip:
    poke @borderColor, 9
    # turn on selectors
    poke @spritesEnabled, peek(@spritesEnabled) or 6
    gosub startFireAnimationSub
return

# --------------------->

# write @selectedItemKey to game board convert @drawTo to x,y
writeGameBoardTileSub:
    gosub boardIndexToCharacterXYSub
    @gameBoard(@drawTo) = @itemValues(@selectedItemKey)
    gosub locateCursorSub
    print @itemTiles$(@selectedItemKey);
return

# set sprite position for @currentSprite at @drawTo
setSpritePositionByTileSub:
    gosub getSpritePositionByTileSub
    gosub updateSpritePositionSub
return

getSpritePositionByTileSub:
    gosub boardIndexToCharacterXYSub
    gosub updatePositionForSprite
    gosub setSpriteRightPositionSub
return

updatePositionForSprite:
    x = 24 + x * 8
    y = 50 + y * 8
return

setSpriteRightPositionSub:
    r = . : if x > 255 then x = x - 256 : r = -1
return

updateSpritePositionSub:
    if not r then poke @spriteScreenRight, peek(@spriteScreenRight) and not (2 ^ @currentSprite)
    if r then poke @spriteScreenRight, peek(@spriteScreenRight) or (2 ^ @currentSprite)
    poke @spriteRegX + @currentSprite * 2, x
    poke @spriteRegY + @currentSprite * 2, y
return

# convert board index to x,y coordinates
boardIndexToCharacterXYSub:
    x = 8 + fn @getColumn(@drawTo) * 3
    y = 2 + int(@drawTo / 8) * 3
return

# write to @gameSidebar sidebar, convert location (@selectedSidebarIndex selected item) (0,1,2,3) to x,y
locateItemSub:
    x = 35
    y = 6 + @selectedSidebarIndex * 3
    gosub locateCursorSub
return

# set cursor position to x,y
locateCursorSub:
    poke 211, x
    poke 214, y
    sys 58732
return

setToolSelectorPositionSub:
    if @selectedSidebarIndex = 0 then poke @spriteRegY + 4, 98
    if @selectedSidebarIndex = 1 then poke @spriteRegY + 4, 122
    if @selectedSidebarIndex = 2 then poke @spriteRegY + 4, 146
    if @selectedSidebarIndex = 3 then poke @spriteRegY + 4, 170
return

setSelectorFrameSub:
    @selectedItemKey = @gameSidebar(@selectedSidebarIndex)
    poke @spriteReg + 1, @selectorSpritePointer(@selectedItemKey)
return

moveCowSub:
    # move cow
    @moved = -1 : c = 0 : @clearTo = @drawTo : r = int(rnd(1) * 4) + 1
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
        @column = fn @getColumn(@drawTo)
        if @column = 0 then if fn @getColumn(@nextValue) > 2 then retryHandler
        if fn @checkGameState(@gameStatePanicking) then if @column = 1 then if fn @getColumn(@nextValue) > 3 then retryHandler
        if @column = 7 then if fn @getColumn(@nextValue) < 5 then retryHandler
        if fn @checkGameState(@gameStatePanicking) then if @column = 6 then if fn @getColumn(@nextValue) < 4 then retryHandler
        
        @newItem = @gameBoard(@nextValue)
        if (@previousItem and @invincible) = @invincible then if (@newItem and @cow) <> @cow then moveItemToNewPositionHandler
        if @newItem = @empty then moveItemToNewPositionHandler

    retryHandler:
        # can't move
        if c > 4 then goto tryMoveItemHandlerSkip
        r = r + 1
        if r > 4 then r = 1
        goto getNewPositionHandler
    
    # add the new cow in the new position from @drawTo to @nextValue
    moveItemToNewPositionHandler:
        @nextKey = 8 : @animationColor = 1
        if (@previousItem and @invincible) <> @invincible then @ufoTarget = @nextValue
        if (@previousItem and @invincible) = @invincible then @nextKey = 20 : @animationColor = 4
        @clearTo = @drawTo
        poke @spriteColor + 5, @animationColor
        # sprite
        @currentSprite = 5
        poke @spriteReg + @currentSprite, @spriteCow

        # starting position
            gosub boardIndexToCharacterXYSub
            @animationX = x : @animationY = y
            gosub updatePositionForSprite
            gosub setSpriteRightPositionSub
            gosub updateSpritePositionSub
            poke @spritesEnabled, peek(@spritesEnabled) or (2 ^ @currentSprite)
            @animationColor = -1
            gosub removeGameBoardItem

        # ending position
            @drawTo = @nextValue
            gosub boardIndexToCharacterXYSub
            @animateToX = x : @animateToY = y

        # animate
        @diffX = (@animateToX - @animationX) / 4 : @diffY = (@animateToY - @animationY) / 4
        for c = . to 3
            @animationX = @animationX + @diffX : @animationY = @animationY + @diffY
            x = @animationX : y = @animationY
            gosub updatePositionForSprite
            gosub setSpriteRightPositionSub
            gosub updateSpritePositionSub
        next

        @selectedItemKey = @nextKey
        gosub writeGameBoardTileSub
        # remove sprite
        poke @spritesEnabled, peek(@spritesEnabled) and not (2 ^ @currentSprite)
        # TODO: add moo sound
        @moved = @nextValue

    tryMoveItemHandlerSkip:
    if @moved < 0 then if a = 9 then gosub clearLogSub : print "Can't move";
return

addFireToBoardSub:
    @gameBoard(@currentPlayerPosition) = @previousItem + @burning

    gosub boardIndexToCharacterXYSub
    c = 2
    # turn tree red
    for a=y to y+2
        if a = y+2 then c = 10
        for b=x to x+2
            poke 55296 + b + (a * 40), c
        next
    next
    gosub clearLogSub : print "cows are panicking";
    if fn @checkGameState(@gameStateLeaking) then if @currentPlayerPosition = @pipeExit then @gameState = fn @addGameState(@gameStateLeakExplosion) : goto addFireToBoardEnd
    @fireIndex = @currentPlayerPosition
    @gameState = fn @addGameState(@gameStatePanicking)

    addFireToBoardEnd:
return

startFireAnimationSub:
    if @fireIndex < 0 then startFireAnimationEnd

    @drawTo = @fireIndex
    # set sprite position
    @currentSprite = 7
    gosub setSpritePositionByTileSub
    # enable sprite
    poke @spritesEnabled, peek(@spritesEnabled) or 128
    poke @spriteReg + @currentSprite, @spriteFire
    @fireIndex = -1

    startFireAnimationEnd:
return

addExplosionToBoardSub:
    @column = fn @getColumn(@currentPlayerPosition)
    @explosionPositions(0) = @currentPlayerPosition
    @explosionPositions(1) = @currentPlayerPosition - 8
    @explosionPositions(2) = @currentPlayerPosition + 8
    @explosionPositions(3) = -1
    @explosionPositions(4) = -1
    if @column > 0 then @explosionPositions(3) = @currentPlayerPosition - 1
    if @column < 7 then @explosionPositions(4) = @currentPlayerPosition + 1
    
    @animationColor = 2
    for i=. to 4
        @drawTo = @explosionPositions(i)

        if @drawTo < 0 then addExplosionToBoardLoopEnd
        if @drawTo > 55 then addExplosionToBoardLoopEnd

        gosub removeGameBoardItem
        if @isMeteor then @selectedItemKey = 9 : gosub writeGameBoardTileSub : poke @spritesEnabled, peek(@spritesEnabled) and 254 : @isMeteor = .

        if fn @checkGameState(@gameStateLeaking) then if @drawTo = @pipeExit then @gameState = fn @addGameState(@gameStateLeakExplosion)

        addExplosionToBoardLoopEnd:
    next

    gosub clearLogSub : print "cows are panicking";
    @gameState = fn @addGameState(@gameStatePanicking)
    
return

removeGameBoardItem:
    if @animationColor < 0 then removeGameBoardItemJump
        @currentSprite = 4
        poke @spriteColor + @currentSprite, @animationColor
        gosub setSpritePositionByTileSub
        poke @spriteReg + @currentSprite, @spritePoof
        poke @spritesEnabled, peek(@spritesEnabled) or (2 ^ @currentSprite)
        for c = . to 100 : next
        poke @spriteReg + @currentSprite, @spritePoof + 1
        for c = . to 100 : next
    removeGameBoardItemJump:
        @selectedItemKey = @empty
        gosub writeGameBoardTileSub
        if @animationColor < 0 then removeGameBoardItemEnd
        poke @spriteReg + @currentSprite, @spritePoof + 2
        for c = . to 100 : next
        poke @spritesEnabled, peek(@spritesEnabled) and not (2 ^ @currentSprite)
    removeGameBoardItemEnd:
return

# pipe connection handler
checkPipeConnectionHandlerSub:
    # loop from begining to see if we reach the end
    @requiredConnection = @pipeLeft
    @pipeExit = @connectionStartPosition
    for i =. to 55
        @checkTile = @gameBoard(@pipeExit)
        
        # check if not connect
        if (@checkTile and @requiredConnection) = . then i = 55 : goto endValidateGameBoardBounds
        # check if complete
        if @pipeExit = @connectionEndPosition then if (@checkTile and @pipeRight) = @pipeRight then @gameState = fn @addGameState(@gameStateComplete) : i = 55 : goto endValidateGameBoardBounds

        # get next required connection
        if (@checkTile and @pipeUp) = @pipeUp then if (@requiredConnection and @pipeUp) = . then @requiredConnection = @pipeDown : @nextIndex = @pipeExit - 8 : goto validateGameBoardBounds
        if (@checkTile and @pipeDown) = @pipeDown then if (@requiredConnection and @pipeDown) = . then @requiredConnection = @pipeUp : @nextIndex = @pipeExit + 8 : goto validateGameBoardBounds
        if (@checkTile and @pipeLeft) = @pipeLeft then if (@requiredConnection and @pipeLeft) = . then @requiredConnection = @pipeRight : @nextIndex = @pipeExit - 1 : goto validateGameBoardBounds
        if (@checkTile and @pipeRight) = @pipeRight then if (@requiredConnection and @pipeRight) = . then @requiredConnection = @pipeLeft : @nextIndex = @pipeExit + 1

        validateGameBoardBounds:
            if @nextIndex < 0 then i = 55 : goto endValidateGameBoardBounds
            if @nextIndex > 55 then i = 55 : goto endValidateGameBoardBounds
            @column = fn @getColumn(@pipeExit)
            if @column = 0 then if @nextIndex = @pipeExit - 1 then i = 55 : goto endValidateGameBoardBounds
            if @column = 7 then if @nextIndex = @pipeExit + 1 then i = 55 : goto endValidateGameBoardBounds

        @pipeExit = @nextIndex
        endValidateGameBoardBounds:
    next

    if fn @checkGameState(@gameStateComplete) then gosub clearLogSub : print "connection complete!";

    # update leaking animation position
    @currentSprite = 6
    @drawTo = @pipeExit
    gosub setSpritePositionByTileSub
    poke @spriteReg + @currentSprite, @spriteGas
return

randomGameEventsHandlerSub:
    @moved = -1
    r = 1 : if fn @checkGameState(@gameStatePanicking) then r = 2
    a = 8 * r : b = 1 * r : @ufoTarget = -1
    for i = . to 56
        @previousItem = @gameBoard(i)
        if (@previousItem and @invincible) <> @invincible then if (@previousItem and @cow) = @cow then @ufoTarget = i
        # skip past last moved to prevent double move
        if i <= @moved then randomGameEventsHandlerEnd
        if (@previousItem and @cow) <> @cow then randomGameEventsHandlerEnd
        r = @cowMovePercent : if @checkGameState(@gameStatePanicking) then r = .
        if rnd(1) > r then randomGameEventsHandlerEnd
        # move cow
        @drawTo = i
        gosub moveCowSub
        
        randomGameEventsHandlerEnd:
        if (@previousItem and @tree) <> @tree then treeEventHandlerEnd
            @drawTo = i
            # grow trees
            if (@previousItem and @growing) = @growing then gosub growTreeHandlerSub
            # remove burning trees
            @animationColor = 0
            if (@previousItem and @destroy) = @destroy then gosub removeGameBoardItem
            # update burning trees to be destroyed
            if (@previousItem and @burning) = @burning then @gameBoard(i) = @tree + @destroy
        treeEventHandlerEnd:
    next
    # if no cow could be abducted, change to alien invasion
    if fn @checkGameState(@gameStateUfoAbduction) then if @ufoTarget = -1 then @gameState = fn @removeGameState(@gameStateUfoAbduction) : @gameState = fn @addGameState(@gameStateAlienInvasion)
return

growTreeHandlerSub:
    @gameBoard(@drawTo) = @tree
    @selectedItemKey = 7
    # sprite 3
    @currentSprite = 3
    poke @spriteColor + @currentSprite, 5
    gosub setSpritePositionByTileSub
    # set first frame
    poke @spriteReg + @currentSprite, @spriteTreeGrow
    # set color
    poke @spriteColor + @currentSprite, 5
    # enable
    poke @spritesEnabled, peek(@spritesEnabled) or (2 ^ @currentSprite)
    # pause
    for c = . to 100 : next
    # show second frame
    poke @spriteReg + @currentSprite, @spriteTreeGrow + 1
    # pause
    for c = . to 100 : next
    gosub writeGameBoardTileSub
    # disable
    poke @spritesEnabled, peek(@spritesEnabled) and not (2 ^ @currentSprite)
return

treeSpawnHandlerSub:
    if rnd(1) > @treeGrowPercent then treeSpawnHandlerEnd
    # spawn a tree in a random position on the game board
    @drawTo = int(rnd(1) * 56)
    if @gameBoard(@drawTo) <> @empty then treeSpawnHandlerEnd

    @selectedItemKey = 17
    gosub writeGameBoardTileSub

    treeSpawnHandlerEnd:
return

updateTimerHandlerSub:
    @timer = @timer - 1 : x = 2
    if @timer < 0 then updateTimerLeak
    
    # update time lower
        y = 17 - @timer : gosub locateCursorSub : print "   "
        goto updateTimerDrawDone

    updateTimerLeak:
        y = 18 + @timer
        gosub locateCursorSub : print  "{rvon}{pink}   {rvof}"
        if @timer = -17 then @gameState = fn @addGameState(@gameStateOver) : gosub clearLogSub : print "time is up!"; : goto updateTimerHandlerEnd

    updateTimerDrawDone:

    # start leak
    if @timer = -1 then gosub startLeakSub
    if @timer > -14 then updateTimerHandlerEnd
        if @timer = -16 then gosub clearLogSub : print "warning! last turn"; : goto updateTimerHandlerShowWarning
        gosub clearLogSub : print "warning!"; 17 + @timer; "turns left";
        updateTimerHandlerShowWarning:
        gosub showWarningSub
    updateTimerHandlerEnd:
return

startLeakSub:
    # set game state
    @gameState = fn @addGameState(@gameStateLeaking)
    # enable sprite
    @currentSprite = 6
    poke @spriteReg + @currentSprite, @spriteGas
    poke @spritesEnabled, peek(@spritesEnabled) or (2 ^ @currentSprite)
    gosub clearLogSub : print "methane is leaking!";
    gosub showWarningSub
return

# feed item handler, move item from feeder to sidebar and replace
nextItemHandlerSub:
    @gameSidebar(0) = @nextItemKey
    gosub locateItemSub : print @itemTiles$(@nextItemKey)
    gosub generateNextPipeSub
return

endPanicHandlerSub:
    if not fn @checkGameState(@gameStatePanicking) then endPanicHandlerEnd
    if rnd(1) > .5 then endPanicHandlerEnd

    @gameState = fn @removeGameState(@gameStatePanicking)
    gosub clearLogSub : print "the cows have settled down";
    
    endPanicHandlerEnd:
return

# alien invasion handler
alienInvasionHandlerSub:
    gosub clearLogSub : print "alien invasion!";
    for i = . to 3
        @drawTo = int(rnd(1) * 56)
        @previousItem = @gameBoard(@drawTo)
        a = (@previousItem and @cow) <> @cow
        if a then i = 3
    next

    # show UFO
    gosub showUfoHandlerSub
    # animate bean and show alien cow
        @selectedItemKey = 20
        gosub boardIndexToCharacterXYSub
        for i = . to 20
            r = (i / 2 - int(i / 2)) * 2
            poke @spriteReg + @currentSprite, @spriteBeam + r
            if i = 15 then gosub writeGameBoardTileSub : goto showAlienCowLoopEnd
            for r = . to 50 : next
            showAlienCowLoopEnd:
        next
    # remove ufo and beam
    gosub hideUfoHandlerSub

    if a then @gameState = fn @removeGameState(@gameStateAlienInvasion)
    gosub hideAlertHandlerSub

    gosub clearLogSub
return

# UFO abduction
ufoAbductionHandlerSub:
    gosub clearLogSub : print "alien abduction!";
    @drawTo = @ufoTarget
    @animationColor = -1
    # show UFO
    gosub showUfoHandlerSub
    # animate bean and show alien cow
        @selectedItemKey = 20
        gosub boardIndexToCharacterXYSub
        for i = . to 20
            r = (i / 2 - int(i / 2)) * 2
            poke @spriteReg + @currentSprite, @spriteBeam + r
            if i = 15 then gosub removeGameBoardItem : goto hideAlienCowLoopEnd
            for r = . to 50 : next
            hideAlienCowLoopEnd:
        next
    # remove ufo and beam
    gosub hideUfoHandlerSub
    @ufoTarget = -1
    @gameState = fn @removeGameState(@gameStateUfoAbduction)
    @gameState = fn @addGameState(@gameStateAlienInvasion)
    gosub hideAlertHandlerSub

    gosub clearLogSub
return

showUfoHandlerSub:
    # show UFO sprite
        @currentSprite = 0
        poke @spriteReg, @spriteUFO
        gosub boardIndexToCharacterXYSub
        gosub updatePositionForSprite
        y = y - 24
        gosub setSpriteRightPositionSub
        gosub updateSpritePositionSub
        poke @spritesEnabled, peek(@spritesEnabled) or (2 ^ @currentSprite)
        for i = . to 300 : next
    # show UFO beam sprite
        @currentSprite = 3
        gosub boardIndexToCharacterXYSub
        gosub updatePositionForSprite
        gosub setSpriteRightPositionSub
        gosub updateSpritePositionSub
        poke @spriteReg + @currentSprite, @spriteBeam
        poke @spriteColor + @currentSprite, 7
        poke @spritesEnabled, peek(@spritesEnabled) or (2 ^ @currentSprite)
return

hideUfoHandlerSub:
    # remove beam
        poke @spritesEnabled, peek(@spritesEnabled) and not (2 ^ @currentSprite)
    # remove UFO
        for i = . to 300 : next
        poke @spritesEnabled, peek(@spritesEnabled) and 254
return

hideAlertHandlerSub:
    x = 34 : y = 20 : gosub locateCursorSub : print "     {down}{5 left}     {down}{5 left}     "
return

# meteor strike
meteorStrikeHandlerSub:
    gosub clearLogSub : print "meteor strike!";
    @newItem = @currentPlayerPosition
    # used for explosion
    @currentPlayerPosition = int(rnd(1) * 56)

    # setup meteor sprite
        @currentSprite = 0
        poke @spriteReg, @spriteMeteor
        @drawTo = @currentPlayerPosition
        gosub boardIndexToCharacterXYSub
        gosub updatePositionForSprite
        # ending position
        @animateToX = x : @animateToY = y
        # starting position
        x = x + 24 : y = y - 24
        @animationX = x  : @animationY = y
        gosub setSpriteRightPositionSub
        gosub updateSpritePositionSub

    # animation
        @diffX = 4
        poke @spritesEnabled, peek(@spritesEnabled) or (2 ^ @currentSprite)
        for c = . to 5
            poke @spriteReg, @spriteMeteor + (c / 2 - int(c / 2)) * 2
            @animationX = @animationX - @diffX : @animationY = @animationY + @diffX
            x = @animationX : y = @animationY
            gosub setSpriteRightPositionSub
            gosub updateSpritePositionSub
        next


    # preform explotion
    @isMeteor = -1
    gosub addExplosionToBoardSub
    # add rock
    @drawTo = @currentPlayerPosition
    @selectedItemKey = 9
    gosub writeGameBoardTileSub
    # remove sprite
    poke @spritesEnabled, peek(@spritesEnabled) and 254
    @gameState = fn @removeGameState(@gameStateMeteor)
    gosub hideAlertHandlerSub

    @currentPlayerPosition = @newItem
    gosub clearLogSub
return

catastrophicEventHandlerSub:
    if @level < 2 then catastrophicEventHandlerEnd
    if fn @checkGameState(@gameStateAlienInvasion) then catastrophicEventHandlerEnd
    if rnd(1) > @catastrophePercent then catastrophicEventHandlerEnd

    c = @level - 1
    c = int(rnd(1) * c) + 1
    if c > 3 then c = 3

    on c goto triggerMeteorEvent, triggerUfoAbductionEvent, triggerAlienInvasionEvent

    triggerMeteorEvent:
    c = @gameStateMeteor
    goto setEventTriggerState

    triggerUfoAbductionEvent:
    c = @gameStateUfoAbduction
    goto setEventTriggerState

    triggerAlienInvasionEvent:
    c = @gameStateAlienInvasion
    # pass through

    setEventTriggerState:
    @gameState = fn @addGameState(c)
    gosub clearLogSub : print "incoming danger!";
    x = 34 : y = 20 : gosub locateCursorSub : print "{red}{5 184}{down}{5 left}{185}{186}e{188}{189}{down}{5 left}{5 190}"
    gosub showWarningSub

    catastrophicEventHandlerEnd:
return

leakExplosionHandlerSub:
    gosub clearLogSub : print "methane explosion!";
    gosub showWarningSub
    # run the remove sub
    @isMeteor = 0 : a = @currentPlayerPosition : @currentPlayerPosition = @pipeExit
    gosub addExplosionToBoardSub
    # remove sprite
    @currentSprite = 6
    poke @spritesEnabled, peek(@spritesEnabled) and not (2 ^ @currentSprite)
    @gameState = fn @removeGameState(@gameStateLeakExplosion)
    poke @spritesEnabled,  peek(@spritesEnabled) or (2 ^ @currentSprite)
    @currentPlayerPosition = a
return

showWarningSub:
    for i = . to 1
        poke @borderColor, 2
        for r = . to 200 : next
        poke @borderColor, 11
        for r = . to 200 : next
    next
return

# replenish tools
replenishToolsSub:
    c = 7
    if @level = 1 then c = 5
    for @selectedSidebarIndex = 3 to 1 step -1
        @selectedItemKey = @levelTools(int(rnd(1) * c))
        if @level > 2 then if @selectedItemKey = 12 then @selectedItemKey = 18
        if @level > 3 then if @selectedItemKey = 11 then @selectedItemKey = 19
        @gameSidebar(@selectedSidebarIndex) = @selectedItemKey
        gosub locateItemSub : print @itemTiles$(@selectedItemKey)
    next
    @toolCount = 3
    gosub clearLogSub : print "tools replenished";
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
    gosub locateCursorSub : print @itemTiles$(@nextItemKey)
return

clearLogSub:
    x=7 : y=24 : gosub locateCursorSub
    print "{black}                          ";
    gosub locateCursorSub
return

fillFeederSub:
    for c = 1 to 6
        for i = . to 1
            @feeder$ = @feeder$ + right$(str$(c), 1)
        next
    next
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
    c = 2
    if @level > 1 then c = c + 1
    if @level > 4 then c = c + 1
    for i = 0 to @level + 9
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

    gosub clearLogSub : print "level"; @level;
return

# 6 9 13 level 1, 15 level 2,4 7 10 12 level 3, 11 14 level 4, 2-3 5 8 level 5
generateSeedSub:
    @seed = int(rnd(.) * 9000)
    if fn @checkGameState(@gameStateChallengeMode) then input "enter a number for the challenge mode seed"; @seed
    if fn @checkGameState(@gameStateChallengeMode) then @level = int(rnd(-@seed) * 5) + 1
return

drawGameBoardSub:
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
    x = 2
    for y = 17 to 2 step -1
        gosub locateCursorSub : print "{rvon}{grn}   {rvof}"
        @timer = @timer + 1
    next
return

joystickResetSub:
    @joystickIdle = -1
    @fireOn = 0
    @directionUp = 0
    @directionDown = 0
    @directionLeft = 0
    @directionRight = 0
return
