# game over screen
for i = . to 56 : @gameBoard = @empty : next
# TODO: add the stat building logic here so that we can display them
for i = . to 3000 : next
# turn off sprites
poke 53269, peek(53269) and 124
# show stats and maybe reset game to create a pause before restarting
x = 10
y = 5 : gosub locateCursorSub : print "{blk}{20 197}"
y = 6 : gosub locateCursorSub : print "{197}{18 32}{197}"
y = 7 : gosub locateCursorSub : print "{197}{4 32}level over{4 32}{197}"
y = 8 : gosub locateCursorSub : print "{197}{18 32}{197}"
y = 9 : gosub locateCursorSub : print "{197}{4 32}press fire{4 32}{197}"
y = 10 : gosub locateCursorSub : print "{197}{18 32}{197}"
y = 11 : gosub locateCursorSub : print "{20 197}"
gosub joystickResetSub

# TODO: add retry or continue options
# we'll need a selector sprite to identify which option is selected
# and move selector handler to change option, there's only 2 so it's a simple cycle
r = .
for i = . to 2000
    gosub joystickInputHandlerSub
    if @fireOn then i = 2000 : goto gameOverLoopDone
    if @directionUp then i = 2000 : r = -1 : goto gameOverLoopDone
    if i >=2000 then i = .
    gameOverLoopDone:
next

if r then retry
