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
dim ci(6)
ci(0)=1
ci(1)=15
ci(2)=12
ci(3)=11
ci(4)=12
ci(5)=15
pp=0
dim pa(56,4)
px=88
xo=px
py=66
poke 53248, px
poke 53249, py
# use right side for sprite 1
poke 53264, peek(53264) or 2
poke 53250, 48
poke 53251, 98

lt=ti
# main game loop, use for loop as it's faster than goto
for gl=. to lm
    # game loop can be used as a counter for things like score multiplier, or to trigger events at certain points in the game
    # pulse color of main sprite
    lt=ti-lt
    if lt<=10 then keyboardHandler
    pp=pp+1: lt=ti
    if pp>5 then pp=0
    poke 53287, ci(pp)
    poke 53288, ci(pp)

    keyboardHandler:
    get in$
    if in$="" then gameLoopDone
    # selecting a tool to use
    if in$="1" then poke 53251, 98
    if in$="2" then poke 53251, 122
    if in$="3" then poke 53251, 146
    if in$="4" then poke 53251, 170

    # play area positioning, 24x24 cells in an 8x7 grid
    nx=px
    ny=py
    if in$="w" then ny=ny-24
    if in$="s" then ny=ny+24
    if in$="a" then nx=nx-24
    if in$="d" then nx=nx+24

    if nx<88 then gameLoopDone
    if ny<66 then gameLoopDone
    if nx>256 then gameLoopDone
    if ny>210 then gameLoopDone

    px=nx
    if px>255 then xo=px-256
    py=ny

    # Set X position
    if px<256 then poke 53248, px: poke 53264, peek(53264) and 254
    if px>255 then poke 53248, xo: poke 53264, peek(53264) or 1
    # Set Y position
    poke 53249, py


    # set over to true (-1) to end game, or false (0) to keep going
    ov=0
    # if game over, set loop to max to end game
    if ov then gl=lm:goto gameLoopDone


    gameLoopDone:
    # best to set it back to 0 (use -1 as next will increment) once reached to prevent the game from ending
    if gl=5 then gl=-1
next
