# This is the main file for the c64 game. It includes all the other files and runs the main loop.
#include "fileLoader.bas"
#include "variables.bas"
#include "sprites.bas"

# light green background
    poke 53281, 13
# brown border
    poke @borderColor, 9

goto start
# putting this up top so that the main loop is closest to the subroutines
gameOver:
# game over
#include "gameOver.bas"

# TODO: retry and continue branch
# continue connected level, go to next level
# continue on game over or challenge mode, end game go to title
# retry, restart current level
if fn @checkGameState(@gameStateChallengeMode) then start
if not fn @checkGameState(@gameStateComplete) then start
goto gameStart

start:
#include "intro.bas"
@level = 0
@seed = -rnd(.)

gameStart:
@level = @level + 1
@catastrophePercent = @level / 10

retry:
i = rnd(@seed)
if fn @checkGameState(@gameStateChallengeMode) then gosub generateChallengeSeedSub

# load game
#include "gameLoad.bas"

# main loop
#include "gameLoop.bas"

goto gameOver
end

#include "subroutines.bas"
