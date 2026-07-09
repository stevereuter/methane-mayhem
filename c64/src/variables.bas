# variables
# start with the most important ones in the main game loop
let x = .
let y = .
# game board types
let @empty = .
let @pipeUp = 1
let @pipeRight = 2
let @pipeDown = 4
let @pipeLeft = 8
let @cow = 16
let @tree = 32
let @rock = 64
# effects, 
let @burning = 128
let @growing = 256
let @invincible = 512
let @destroy = 1024
let @move = 2048
let @blocked = 4096
let @highPercent = 8192
let @unused = 16384
# NOTE: there is no 16th bit as that is used for the sign in C64 BASIC
# NOTE: the idea here being that an item would contain the affected type and effect, so the giddy up would be 2048+16 (move cow), the axe would be 1024+32 (destroy tree), and the cone would be 4096+16+32 (blocked cow and tree)

let @checkIndex = .
let @nextIndex = .
let @checkTile = .
let @requiredConnection = .
let @column = .
let @connectionStartPosition = .
let @connectionEndPosition = .
let @isComplete = .
let @selectedItemKey = .
let @selectedItem = .
let @previousItem = .

let @gameLoop = .
let @isGameOver = .
let @currentPlayerPostision = .
let @selectedSidebarIndex = .
let @direction = .
let @nextItemKey = .

# NOTE: will also need events: cows moving, trees spawning, fire spreading, rocks falling (meteors), add panic to cows near fire or death (higher chance of moving), alien cows spawning (delivered by UFO if taken in the past)

# NOTE: going to need a cross reference array for all items and their images

let @printText$ = ""
let @loopMax = 100

# arrays
dim @colorPulse(6)
# game board, 8x7 grid for 56 total cells
dim @gameBoard(56)
dim @gameSidebar(4)
# items
dim @itemValues(15)
# board tiles
dim @itemTiles$(15)

@colorPulse(0) = 1
@colorPulse(1) = 15
@colorPulse(2) = 12
@colorPulse(3) = 11
@colorPulse(4) = 12
@colorPulse(5) = 15

# all item images
# TODO: create a cross reference for items and their attributes
# empty
@itemTiles$(0) = "   {down}{3 left}   {down}{3 left}   "
@itemValues(0) = @empty
# pipe vertical
@itemTiles$(1) = "{lightgrey} {36} {down}{3 left} {36} {down}{3 left} {36} "
@itemValues(1) = @pipeUp + @pipeDown
# pipe horizontal
@itemTiles$(2) = "{lightgrey}   {down}{3 left}{35}{35}{35}{down}{3 left}   "
@itemValues(2) = @pipeLeft + @pipeRight
# pipe corner down right
@itemTiles$(3) = "{lightgrey}   {down}{3 left} {39}{35}{down}{3 left} {36} "
@itemValues(3) = @pipeDown + @pipeRight
# pipe corner down left
@itemTiles$(4) = "{lightgrey}   {down}{3 left}{35}{64} {down}{3 left} {36} "
@itemValues(4) = @pipeDown + @pipeLeft
# pipe corner up right
@itemTiles$(5) = "{lightgrey} {36} {down}{3 left} {37}{35}{down}{3 left}   "
@itemValues(5) = @pipeUp + @pipeRight
# pipe corner up left
@itemTiles$(6) = "{lightgrey} {36} {down}{3 left}{35}{38} {down}{3 left}   "
@itemValues(6) = @pipeUp + @pipeLeft
# tree
@itemTiles$(7) = "{green}{192}{193}{194}{down}{3 left}{208}{209}{210}{down}{3 left}{160}{161}{162}"
@itemValues(7) = @tree
# cow
@itemTiles$(8) = "{white}{195}{196}{197}{down}{3 left}{211}{212}{213}{down}{3 left}{163}{164}{165}"
@itemValues(8) = @cow
# rock
@itemTiles$(9) = "{darkgrey}{198}{199}{200}{down}{3 left}{214}{215}{216}{down}{3 left}{166}{167}{168}"
@itemValues(9) = @rock
# giddy up
@itemTiles$(10) = "{yellow}{201}{202}{32}{down}{3 left}{217}{218}{219}{down}{3 left}{32}{170}{171}"
@itemValues(10) = @move + @cow
# cone
@itemTiles$(11) = "{orange}{32}{205}{32}{down}{3 left}{220}{221}{222}{down}{3 left}{172}{173}{174}"
@itemValues(11) = @blocked + @cow + @tree
# axe
@itemTiles$(12) = "{red}{32}{58}{59}{down}{3 left}{32}{60}{32}{down}{3 left}{32}{61}{32}"
@itemValues(12) = @destroy + @tree

# start
@itemTiles$(13) = "{lightgrey}{down}{left}{35}"
@itemValues(13) = .
# end
@itemTiles$(14) = "{lightgrey}{down}{3 right}{35}"
@itemValues(14) = .
# TODO: items to add: pick axe (destroy rock), dynamite (destroy large area and create fire), UFO (remove cows from the board), chainsaw? (destroy multiple trees), water/fire extinguisher (destroy fire stop spread), match (burn tree), tranquilizer? (calm cows)



# {space}, {return}, {shift-return}, {clr}, {clear}, {home}, {del}, {inst}, {stop}, {run/stop}, {esc}, {cursor right}, {crsr right}, {cursor left}, {crsr left}, {down}, {cursor down}, {crsr down}, {cursor up}, {crsr dup}, {uppercase}, {upper}, {swuc}, {cset1}, {lowercase}, {lower}, {cset0}, {black}, {blk}, {white}, {wht}, {red}, {cyan}, {cyn}, {purple}, {pur}, {green}, {grn}, {blue}, {blu}, {yellow}, {yel}, {orange}, {brown}, {pink}, {light-red}, {gray1}, {darkgrey}, {grey}, {lightgreen}, {lgrn}, {lightblue}, {lblu}, {lightgrey}, {grey3}, {rvs on}, {rvon}, {rvs off}, {rvof}, {dish}, {ensh}, {f1}, {f3}, {f5}, {f7}, {f2}, {f4}, {f6}, {f8}, {ctrl-c}, {ctrl-e}, {ctrl-h}, {ctrl-i}, {ctrl-m}, {ctrl-n}, {ctrl-r}, {ctrl-s}, {ctrl-t}, {ctrl-q}, {ctrl-1}, {ctrl-2}, {ctrl-3}, {ctrl-4}, {ctrl-5}, {ctrl-6}, {ctrl-7}, {ctrl-8}, {ctrl-9}, {ctrl-0}, {ctrl-/}, {c=1}, {c=2}, {c=3}, {c=4}, {c=5}, {c=6}, {c=7}, {c=8}
