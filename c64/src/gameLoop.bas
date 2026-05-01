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
dim @colorPulse(6)
@colorPulse(0) = 1
@colorPulse(1) = 15
@colorPulse(2) = 12
@colorPulse(3) = 11
@colorPulse(4) = 12
@colorPulse(5) = 15
# pointer color
@colorPulsePointer = 0
# x position
@positionX = 88
# x right side
@sidebarX = @positionX
# y position
@positionY = 66
# new x position
@newPositionX = 0
# new y position
@newPositionY = 0
poke 53248, @positionX
poke 53249, @positionY
# use right side for sprite 1
poke 53264, peek(53264) or 2
poke 53250, 48
poke 53251, 98
# time difference 0-9, is reset at 10 giffies
@timeDifference = TI
@boardIndex = 0
@selectedItemIndex = 0
# main game loop, use for loop as it's faster than goto
for @gameLoop=. to @loopMax
    gosub animateSelectorSub
    # TODO: may have to convert this to ASC as we will need enter and function keys
    get @keyInput$
    if @keyInput$ = "" then @gameLoopDone
    @keyInputAsc = ASC(@keyInput$)
    # selecting a tool to use
    gosub itemSelectorHandlerSub
    # selecting a cell on the board
    gosub boardSelectorHandlerSub
    # TODO: handle item placement here, will need to check if it's available for the current selected item
    gosub placeItemHandlerSub

    # TODO: handle win condition logic

    # TODO: handle game over logic
    # set over to true (-1) to end game, or false (0) to keep going
    @isGameOver = .
    # if game over, set loop to max to end game
    if @isGameOver then @gameLoop = @loopMax : goto @gameLoopDone


    @gameLoopDone:
    # best to set it back to 0 (use -1 as next will increment) once reached to prevent the game from ending
    # TODO: need to determine if we are going to use the index for anything
    if @gameLoop = 5 then @gameLoop = -1
next
