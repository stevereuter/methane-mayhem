# variables
# start with the most important ones in the main game loop
x=.:y=.
# game board values: pipe ends, cow, tree, rock,
up=1:rt=2:dn=4:lt=8:cw=16:tr=32:rk=64:
# effects: burning, growing, invincible, destroy, move, blocked
br=128:gr=256:iv=512:dy=1024:mv=2048:bl=4096
# NOTE: the idea here being that an item would contain the affected type and effect, so the giddy up would be 2048+16 (move cow), the axe would be 1024+32 (destroy tree), and the cone would be 4096+16+32 (blocked cow and tree)
# game loop, over, board index, selected item, direction
gl=.:ov=.:bi=.:si=.:di=.:fd=.

lm=100
print "Initializing variables..."

# arrays
# game board, 8x7 grid for 56 total cells
dim gb(56)
# items
dim it(4)
# board tiles
dim bt$(13)

# seed any array data here if needed
# TODO: create a cross reference for items and their attributes
# empty
bt$(0)="   {down}{left}{left}{left}   {down}{left}{left}{left}   "
# pipe horizontal
bt$(1)="{lightgrey} {36} {down}{left}{left}{left} {36} {down}{left}{left}{left} {36} "
# pipe vertical
bt$(2)="{lightgrey}   {down}{left}{left}{left}{35}{35}{35}{down}{left}{left}{left}   "
# pipe corner down right
bt$(3)="{lightgrey}   {down}{left}{left}{left} {39}{35}{down}{left}{left}{left} {36} "
# pipe corner down left
bt$(4)="{lightgrey}   {down}{left}{left}{left}{35}{64} {down}{left}{left}{left} {36} "
# pipe corner up right
bt$(5)="{lightgrey} {36} {down}{left}{left}{left} {37}{35}{down}{left}{left}{left}   "
# pipe corner up left
bt$(6)="{lightgrey} {36} {down}{left}{left}{left}{35}{38} {down}{left}{left}{left}   "
# tree
bt$(7)="{green}{192}{193}{194}{down}{left}{left}{left}{208}{209}{210}{down}{left}{left}{left}{160}{161}{162}"
# cow
bt$(8)="{white}{195}{196}{197}{down}{left}{left}{left}{211}{212}{213}{down}{left}{left}{left}{163}{164}{165}"
# rock
bt$(9)="{darkgrey}{198}{199}{200}{down}{left}{left}{left}{214}{215}{216}{down}{left}{left}{left}{166}{167}{168}"
# giddy up
bt$(10)="{yellow}{201}{202}{32}{down}{left}{left}{left}{217}{218}{219}{down}{left}{left}{left}{32}{170}{171}"
# cone
bt$(11)="{orange}{32}{205}{32}{down}{left}{left}{left}{220}{221}{222}{down}{left}{left}{left}{172}{173}{174}"
# axe
bt$(12)="{red}{32}{58}{59}{down}{left}{left}{left}{32}{60}{32}{down}{left}{left}{left}{32}{61}{32}"

# {space}, {return}, {shift-return}, {clr}, {clear}, {home}, {del}, {inst}, {stop}, {run/stop}, {esc}, {cursor right}, {crsr right}, {cursor left}, {crsr left}, {down}, {cursor down}, {crsr down}, {cursor up}, {crsr dup}, {uppercase}, {upper}, {swuc}, {cset1}, {lowercase}, {lower}, {cset0}, {black}, {blk}, {white}, {wht}, {red}, {cyan}, {cyn}, {purple}, {pur}, {green}, {grn}, {blue}, {blu}, {yellow}, {yel}, {orange}, {brown}, {pink}, {light-red}, {gray1}, {darkgrey}, {grey}, {lightgreen}, {lgrn}, {lightblue}, {lblu}, {lightgrey}, {grey3}, {rvs on}, {rvon}, {rvs off}, {rvof}, {dish}, {ensh}, {f1}, {f3}, {f5}, {f7}, {f2}, {f4}, {f6}, {f8}, {ctrl-c}, {ctrl-e}, {ctrl-h}, {ctrl-i}, {ctrl-m}, {ctrl-n}, {ctrl-r}, {ctrl-s}, {ctrl-t}, {ctrl-q}, {ctrl-1}, {ctrl-2}, {ctrl-3}, {ctrl-4}, {ctrl-5}, {ctrl-6}, {ctrl-7}, {ctrl-8}, {ctrl-9}, {ctrl-0}, {ctrl-/}, {c=1}, {c=2}, {c=3}, {c=4}, {c=5}, {c=6}, {c=7}, {c=8}
