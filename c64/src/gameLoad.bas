# load the game here
# reset variables, load data, etc.

# light green background
poke 53281, 13
# brown border
poke 53280, 9

print "{clr}{brown}             methane mayhem"
r1$="       {rvon}                          {rvof}"
print r1$
r2$="       {rvon} {rvof}                        {rvon} {rvof}"
r3$="       {rvon} {rvof}                        {rvon} {rvof} {rvon}     {rvof}"
r4$="       {rvon} {rvof}                        {rvon} {rvof} {rvon} {rvof}   {rvon} {rvof}"

for i=. to 2
    print r2$
next
print r3$
for i=. to 11
    print r4$
next
print r3$
for i=. to 3
    print r2$
next

print r1$;

# TODO: temp remove
# draw tree in position 0: x=o y=0
tx$="{192}{193}{194}{down}{left}{left}{left}{208}{209}{210}{down}{left}{left}{left}{160}{161}{162}"
x=8
y=2
gosub writeTextSub

# draw cow in position 10: x=1, y=1
tx$="{195}{196}{197}{down}{left}{left}{left}{211}{212}{213}{down}{left}{left}{left}{163}{164}{165}"
x=11
y=5
gosub writeTextSub

# draw rock in position 20: x=2, y=2
tx$="{198}{199}{200}{down}{left}{left}{left}{214}{215}{216}{down}{left}{left}{left}{166}{167}{168}"
x=14
y=8
gosub writeTextSub
