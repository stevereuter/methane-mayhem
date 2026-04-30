# load the game here
# reset variables, load data, etc.

# light green background
poke 53281, 13
# brown border
poke 53280, 9

r1$="       {rvon}                          {rvof} {rvon}next {rvof}"
r2$="       {rvon} {rvof}                        {rvon} {rvof}"
r3$="       {rvon} {rvof}                        {rvon} {rvof} {rvon} {rvof}{93}{93}{93}{rvon} {rvof}"
r4$="       {rvon} {rvof}                        {rvon} {rvof} {rvon} {rvof}   {rvon} {rvof}"
r5$="       {rvon}                          {rvof}"
r6$="       {rvon}                          {rvof}"
r7$="       {rvon} {rvof}                        {rvon} {rvof} {rvon}     {rvof}"

print "{clr}{brown}             methane mayhem"
print r1$

for i=. to 2
    print r4$
next
print r3$
for i=. to 11
    print r4$
next
print r7$
for i=. to 3
    print r2$
next

print r6$;

# TODO: need to fill teh pipe feeder with the next 3 random pipes, if we use a string we can just draw 3 and convert the current one below from the forth. A string will be easier to feed later, or just a move up in array

x=36
@nextItemFeeder=int(rnd(.)*6)+1
gosub writeFeederHandlerSub

# TODO: add @items
for @selectedItem=1 to 3
    @items(@selectedItem)=9+@selectedItem
    tx$=@boardTiles$(@items(@selectedItem))
    gosub writeItemSub
NEXT

# TODO: temp remove, create random pipe for item sidebar
rn=int(rnd(.)*6)+1
tx$=@boardTiles$(rn)
@items(0)=rn
@selectedItem=0
gosub writeItemSub

# TODO: temp remove
# draw tree, cow, and rock in random positions on the board for testing
for i=7 to 9
    tx$=@boardTiles$(i)
    @boardIndex=int(rnd(.)*56)
    gosub writeGameBoardTileSub
next

# TODO: need the random start and end points
