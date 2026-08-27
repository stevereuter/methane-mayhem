# pointer color
@colorPulsePointer = 0
# x position
@positionX = @startX
# x right side
@sidebarX = @positionX
# y position
@positionY = @startY
# new x position
@newPositionX = 0
# new y position
@newPositionY = 0
poke @spriteRegX + 2, @positionX
poke @spriteRegY + 2, @positionY
# use right side for sprite 1
poke @spriteScreenRight, peek(@spriteScreenRight) or 4
poke @spriteRegX + 4, 48
poke @spriteRegY + 4, 98
poke @selectorSpriteColor, 1
poke @spriteColor + 2, 1
# turn on sprites
poke @spritesEnabled, peek(@spritesEnabled) or 6
# time difference 0-9, is reset at 10 giffies
@timeDifference = TI
@currentPlayerPostision = 0
@selectedSidebarIndex = 0
gosub setSelectorFrameSub

@gameState = @gameState and @gameStateChallengeMode
# main game loop, use for loop as it's faster than goto
for @gameLoop=. to @loopMax
    gosub animateSelectorSub
    poke @spriteReg + 7, @spriteFire + @burnAnimation
    @burnAnimation = @burnAnimation + 1
    if @burnAnimation = 2 then @burnAnimation = 0

    gosub joystickInputHandlerSub
    # selecting a tool to use
    gosub playerSelectItemHandlerSub

    if @joystickIdle then gameLoopSkip
    # selecting a cell on the board
    gosub playerMoveHandlerSub
    gosub placeItemHandlerSub

    # if game over, set loop to max to end game
    if fn @checkGameState(@gameStateOver) then @gameLoop = @loopMax : goto gameLoopDone
    if fn @checkGameState(@gameStateComplete) then @gameLoop = @loopMax : goto gameLoopDone

    gameLoopSkip:
    # best to set it back to 0 (use -1 as next will increment) once reached to prevent the game from ending
    # TODO: need to determine if we are going to use the index for anything
    if @gameLoop = 5 then @gameLoop = -1
    gameLoopDone:
next
if fn @checkGameState(@gameStateChallengeMode) then gameStateCompleteCheckEnd
if not fn @checkGameState(@gameStateComplete) then gameStateCompleteCheckEnd
    @level = @level + 1
    @catastrophePercent = @level / 10
    for i = . to 3000 : next
    goto gameStart
gameStateCompleteCheckEnd:
