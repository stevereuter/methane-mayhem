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
# draw tree, cow, and rock in random positions on the board for testing
for i=. to 2
    tx$=bt$(i)
    bi=int(rnd(.)*56)
    gosub writeGameBoardTileSub
    x=0:y=i+3:tx$=str$(bi):gosub writeTextSub
next
