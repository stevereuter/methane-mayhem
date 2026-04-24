# variables
# start with the most important ones in the main game loop
gl=0:ov=0:bi=0:si=0

lm=100
print "Initializing variables..."

# arrays
# game board, 8x7 grid for 56 total cells
dim gb(56)
# board tiles
dim bt$(10)

# seed any array data here if needed
# TODO: sync pipe indexes
# empty
bt$(0)="   {down}{left}{left}{left}   {down}{left}{left}{left}   "
# pipe horizontal
bt$(1)=" {36} {down}{left}{left}{left} {36} {down}{left}{left}{left} {36} "
# pipe vertical
bt$(2)="   {down}{left}{left}{left}{35}{35}{35}{down}{left}{left}{left}   "
# pipe corner down right
bt$(3)="   {down}{left}{left}{left} {39}{35}{down}{left}{left}{left} {36} "
# pipe corner down left
bt$(4)="   {down}{left}{left}{left}{35}{64} {down}{left}{left}{left} {36} "
# pipe corner up right
bt$(5)=" {36} {down}{left}{left}{left} {37}{35}{down}{left}{left}{left}   "
# pipe corner up left
bt$(6)=" {36} {down}{left}{left}{left}{35}{38} {down}{left}{left}{left}   "
# tree
bt$(7)="{192}{193}{194}{down}{left}{left}{left}{208}{209}{210}{down}{left}{left}{left}{160}{161}{162}"
# cow
bt$(8)="{195}{196}{197}{down}{left}{left}{left}{211}{212}{213}{down}{left}{left}{left}{163}{164}{165}"
# rock
bt$(9)="{198}{199}{200}{down}{left}{left}{left}{214}{215}{216}{down}{left}{left}{left}{166}{167}{168}"

# {space}, {return}, {shift-return}, {clr}, {clear}, {home}, {del}, {inst}, {stop}, {run/stop}, {esc}, {cursor right}, {crsr right}, {cursor left}, {crsr left}, {down}, {cursor down}, {crsr down}, {cursor up}, {crsr dup}, {uppercase}, {upper}, {swuc}, {cset1}, {lowercase}, {lower}, {cset0}, {black}, {blk}, {white}, {wht}, {red}, {cyan}, {cyn}, {purple}, {pur}, {green}, {grn}, {blue}, {blu}, {yellow}, {yel}, {orange}, {brown}, {pink}, {light-red}, {gray1}, {darkgrey}, {grey}, {lightgreen}, {lgrn}, {lightblue}, {lblu}, {lightgrey}, {grey3}, {rvs on}, {rvon}, {rvs off}, {rvof}, {dish}, {ensh}, {f1}, {f3}, {f5}, {f7}, {f2}, {f4}, {f6}, {f8}, {ctrl-c}, {ctrl-e}, {ctrl-h}, {ctrl-i}, {ctrl-m}, {ctrl-n}, {ctrl-r}, {ctrl-s}, {ctrl-t}, {ctrl-q}, {ctrl-1}, {ctrl-2}, {ctrl-3}, {ctrl-4}, {ctrl-5}, {ctrl-6}, {ctrl-7}, {ctrl-8}, {ctrl-9}, {ctrl-0}, {ctrl-/}, {c=1}, {c=2}, {c=3}, {c=4}, {c=5}, {c=6}, {c=7}, {c=8}
