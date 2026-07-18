# game over screen
for i = . to 56 : @gameBoard = @empty : next
for i = . to 3000 : next
# turn off sprites
poke 53269, peek(53269) and 252
# show stats and maybe reset game to create a pause before restarting
x = 10
y = 5 : @printText$ = "{blk}{20 197}" : gosub writeTextSub
y = 6 : @printText$ = "{197}{18 32}{197}" : gosub writeTextSub
y = 7 : @printText$ = "{197}{4 32}game over!{4 32}{197}" : gosub writeTextSub
y = 8 : @printText$ = "{197}{18 32}{197}" : gosub writeTextSub
y = 9 : @printText$ = "{197}{3 32}press return{3 32}{197}" : gosub writeTextSub
y = 10 : @printText$ = "{197}{18 32}{197}" : gosub writeTextSub
y = 11 : @printText$ = "{20 197}" : gosub writeTextSub
for i = . to 2000
    get @keyInput$
    if @keyInput$ <> "" then if ASC(@keyInput$) = 13 then i = 2000 : goto gameOverLoopDone
    if i >=2000 then i = .
    gameOverLoopDone:
next

