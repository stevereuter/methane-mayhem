# This is the main file for the c64 game. It includes all the other files and runs the main loop.
#include "fileLoader.bas"
#include "variables.bas"
#include "sprites.bas"

# light green background
    poke 53281, 13
# brown border
    poke 53280, 9

goto start
# putting this up top so that the main loop is closest to the subroutines
gameOver:
# game over
#include "gameOver.bas"

goto start

start:
#include "intro.bas"

gameStart:
# load game
#include "gameLoad.bas"

# main loop
#include "gameLoop.bas"

goto gameOver
end

#include "subroutines.bas"
