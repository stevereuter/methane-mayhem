# This is the main file for the c64 game. It includes all the other files and runs the main loop.
#include "variables.bas"
#include "splash.bas"
#include "characters.bas"
#include "sprites.bas"

goto gameStart
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

end

# main loop
#include "gameLoop.bas"

goto gameOver
end

#include "subroutines.bas"
#include "data.bas"
