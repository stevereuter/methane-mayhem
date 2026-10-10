# turn off sprites
poke 53269, peek(53269) and 124
# game over screen
x = 10 : y = 3 : gosub locateCursorSub : print "{blk}{20 197}"
for y = 4 to 19
    gosub locateCursorSub : print "{197}{18 32}{197}"
next
y = 20 : gosub locateCursorSub : print "{20 197}"
x = 16 : y = 5 : gosub locateCursorSub : print "level "; @level

x = 12 : y = 7 : gosub locateCursorSub
if not fn @checkGameState(@gameStateComplete) then print "failed{9 32}{red}0"
if fn @checkGameState(@gameStateComplete) then print "{blk}complete{4 32}{grn}1000"

# get board stats
for i = . to 56
    @checkTile = @gameBoard(i)
    if (@checkTile and @cow) = @cow then @gameStats%(2) = @gameStats%(2) - 1
    if (@checkTile and @tree) = @tree then @gameStats%(3) = @gameStats%(3) - 1
    if (@checkTile and @rock) = @rock then @gameStats%(4) = @gameStats%(4) - 1
next
c = @gameStats%(0)
if fn @checkGameState(@gameStateComplete) then c = c + 1000
a = (@gameStats%(5) - @gameStats%(1)) * 20
c = a + c
if @gameStats%(2) < 1 then c = c + 250
if @gameStats%(3) < 1 then c = c + 50
if @gameStats%(4) < 1 then c = c + 100
b = @timer >= 0
if b then c = c + 500

# show stats and maybe reset game to create a pause before restarting
y = 8 : gosub locateCursorSub : print "{blk}waste{red}";
x = 28 - len(str$(a)) : gosub locateCursorSub : print a

x = 12 : y = 9 : gosub locateCursorSub : print "{blk}tree hugger"
if @gameStats%(3) > 0 then x = 27 : gosub locateCursorSub : print "{red}0"
if @gameStats%(3) < 1 then x = 26 : gosub locateCursorSub : print "{grn}50"

x = 12 : y = 10 : gosub locateCursorSub : print "{blk}pet rocks"
if @gameStats%(4) > 0 then x = 27 : gosub locateCursorSub : print "{red}0"
if @gameStats%(4) < 1 then x = 25 : gosub locateCursorSub : print "{grn}100"

x = 12 : y = 11 : gosub locateCursorSub : print "{blk}animal lover"
if @gameStats%(2) > 0 then x = 27 : gosub locateCursorSub : print "{red}0"
if @gameStats%(2) < 1 then x = 25 : gosub locateCursorSub : print "{grn}250"

x = 12 : y = 12 : gosub locateCursorSub : print "{blk}clean air"
if not b then x = 27 : gosub locateCursorSub : print "{red}0"
if b then x = 25 : gosub locateCursorSub : print "{grn}500"

x = 12 : y = 14 : gosub locateCursorSub : print "{blk}total"
y = 15 : gosub locateCursorSub : print "score"

x = 28 - len(str$(c)) : y = 14 : gosub locateCursorSub : print c
b = @gameStats%(0) + c
x = 28 - len(str$(b)) : y = 15 : gosub locateCursorSub : print b

# clear the board
for i = . to 56 : @gameBoard = @empty : next

gosub joystickResetSub
r = .

x = 12 : y = 17 : gosub locateCursorSub : print "fire to continue"
x = 14 : y = 18 : gosub locateCursorSub : print "up to retry"
for i = . to 2000
    gosub joystickInputHandlerSub
    if @fireOn then i = 2000 : goto gameOverLoopDone
    if @directionUp then i = 2000 : r = -1 : goto gameOverLoopDone
    if i >=2000 then i = .
    gameOverLoopDone:
next

if r then retry
@gameStats%(0) = b
