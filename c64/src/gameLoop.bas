# colors
# 0	black
# 11 dark grey
# 12 grey
# 15 light grey
# 1	white
# 9	brown
# 8	orange
# 4	purple
# 2	red
# 10 pink
# 7	yellow
# 5	green
# 13 light green
# 3	cyan
# 14 light blue
# 6	blue

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
# turn on sprites
poke @spritesEnabled, peek(@spritesEnabled) or 6
# time difference 0-9, is reset at 10 giffies
@timeDifference = TI
@currentPlayerPostision = 0
@selectedSidebarIndex = 0

@gameState = @gameState and @gameStateChallengeMode
# main game loop, use for loop as it's faster than goto
for @gameLoop=. to @loopMax
    gosub animateSelectorSub
    poke @spriteReg + 7, @spriteFire + @burnAnimation
    @burnAnimation = @burnAnimation + 1
    if @burnAnimation = 2 then @burnAnimation = 0

    # TODO: may have to convert this to ASC as we will need enter and function keys
    get @keyInput$
    if @keyInput$ = "" then gameLoopSkip
    @keyInputAsc = ASC(@keyInput$)
    # selecting a tool to use
    gosub playerSelectItemHandlerSub
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
    for i = . to 3000 : next
    goto gameStart
gameStateCompleteCheckEnd:
