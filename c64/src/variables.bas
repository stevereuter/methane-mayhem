# variables
# start with the most important ones in the main game loop
x=.:y=.
# game board types: pipe ends (4 ends, 6 variations), cow, tree, rock
cn=1:up=2:rt=4:dn=8:lt=16:cw=32:tr=64:rk=128
# effects: burning, growing, invincible, destroy, move, blocked, high percent (panicked cows), unused (this is the max)
br=256:gr=512:iv=1024:dy=2048:mv=4096:bl=8192:hp=16384:uu=32768
# NOTE: the idea here being that an item would contain the affected type and effect, so the giddy up would be 2048+16 (move cow), the axe would be 1024+32 (destroy tree), and the cone would be 4096+16+32 (blocked cow and tree)
# game loop, over, board index, selected item, direction
@gameLoop=.:@isGameOver=.:@boardIndex=.:@selectedItem=.:@direction=.:@nextItemFeeder=.

# NOTE: will also need events: cows moving, trees spawning, fire spreading, rocks falling (meteors), add panic to cows near fire or death (higher chance of moving), alien cows spawning (delivered by UFO if taken in the past)

# NOTE: going to need a cross reference array for all items and their images

lm=100

# arrays
# game board, 8x7 grid for 56 total cells
dim @gameBoard(56)
# items
dim @items(4)
# board tiles
dim @boardTiles$(13)

# all item images
# TODO: create a cross reference for items and their attributes
# empty
@boardTiles$(0)="   {down}{left}{left}{left}   {down}{left}{left}{left}   "
# pipe horizontal
@boardTiles$(1)="{lightgrey} {36} {down}{left}{left}{left} {36} {down}{left}{left}{left} {36} "
# pipe vertical
@boardTiles$(2)="{lightgrey}   {down}{left}{left}{left}{35}{35}{35}{down}{left}{left}{left}   "
# pipe corner down right
@boardTiles$(3)="{lightgrey}   {down}{left}{left}{left} {39}{35}{down}{left}{left}{left} {36} "
# pipe corner down left
@boardTiles$(4)="{lightgrey}   {down}{left}{left}{left}{35}{64} {down}{left}{left}{left} {36} "
# pipe corner up right
@boardTiles$(5)="{lightgrey} {36} {down}{left}{left}{left} {37}{35}{down}{left}{left}{left}   "
# pipe corner up left
@boardTiles$(6)="{lightgrey} {36} {down}{left}{left}{left}{35}{38} {down}{left}{left}{left}   "
# tree
@boardTiles$(7)="{green}{192}{193}{194}{down}{left}{left}{left}{208}{209}{210}{down}{left}{left}{left}{160}{161}{162}"
# cow
@boardTiles$(8)="{white}{195}{196}{197}{down}{left}{left}{left}{211}{212}{213}{down}{left}{left}{left}{163}{164}{165}"
# rock
@boardTiles$(9)="{darkgrey}{198}{199}{200}{down}{left}{left}{left}{214}{215}{216}{down}{left}{left}{left}{166}{167}{168}"
# giddy up
@boardTiles$(10)="{yellow}{201}{202}{32}{down}{left}{left}{left}{217}{218}{219}{down}{left}{left}{left}{32}{170}{171}"
# cone
@boardTiles$(11)="{orange}{32}{205}{32}{down}{left}{left}{left}{220}{221}{222}{down}{left}{left}{left}{172}{173}{174}"
# axe
@boardTiles$(12)="{red}{32}{58}{59}{down}{left}{left}{left}{32}{60}{32}{down}{left}{left}{left}{32}{61}{32}"
# TODO: items to add: pick axe (destroy rock), dynamite (destroy large area and create fire), UFO (remove cows from the board), chainsaw? (destroy multiple trees), water/fire extinguisher (destroy fire stop spread), match (burn tree), tranquilizer? (calm cows), shovel? (move rock)

# {space}, {return}, {shift-return}, {clr}, {clear}, {home}, {del}, {inst}, {stop}, {run/stop}, {esc}, {cursor right}, {crsr right}, {cursor left}, {crsr left}, {down}, {cursor down}, {crsr down}, {cursor up}, {crsr dup}, {uppercase}, {upper}, {swuc}, {cset1}, {lowercase}, {lower}, {cset0}, {black}, {blk}, {white}, {wht}, {red}, {cyan}, {cyn}, {purple}, {pur}, {green}, {grn}, {blue}, {blu}, {yellow}, {yel}, {orange}, {brown}, {pink}, {light-red}, {gray1}, {darkgrey}, {grey}, {lightgreen}, {lgrn}, {lightblue}, {lblu}, {lightgrey}, {grey3}, {rvs on}, {rvon}, {rvs off}, {rvof}, {dish}, {ensh}, {f1}, {f3}, {f5}, {f7}, {f2}, {f4}, {f6}, {f8}, {ctrl-c}, {ctrl-e}, {ctrl-h}, {ctrl-i}, {ctrl-m}, {ctrl-n}, {ctrl-r}, {ctrl-s}, {ctrl-t}, {ctrl-q}, {ctrl-1}, {ctrl-2}, {ctrl-3}, {ctrl-4}, {ctrl-5}, {ctrl-6}, {ctrl-7}, {ctrl-8}, {ctrl-9}, {ctrl-0}, {ctrl-/}, {c=1}, {c=2}, {c=3}, {c=4}, {c=5}, {c=6}, {c=7}, {c=8}
