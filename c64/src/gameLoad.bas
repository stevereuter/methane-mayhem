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

# TODO: need to fill teh pipe feeder with the next 3 random pipes, if we use a string we can just draw 3 and convert the current one below from the forth. A string will be easier to feed later, or just a move up in array

# TODO: sync pipe indexes
dim pa$(6)
pa$(0)="{91}"
pa$(1)="{92}"
pa$(2)="{94}"
pa$(3)="{95}"
pa$(4)="{43}"
pa$(5)="{44}"
x=36
for y=2 to 4
    rn=int(rnd(.)*6)
    tx$=pa$(rn)
    gosub writeTextSub
next

# TODO: temp remove, create random pipe for item sidebar
rn=int(rnd(.)*6)+1
tx$=bt$(rn)
si=0
gosub writeItemSub

# TODO: temp remove
# draw tree, cow, and rock in random positions on the board for testing
for i=1 to 9
    tx$=bt$(i)
    bi=int(rnd(.)*56)
    gosub writeGameBoardTileSub
next

# TODO: need the random start and end points
