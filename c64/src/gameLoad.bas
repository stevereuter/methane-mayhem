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

x = 36
gosub generateNextItemSub

# TODO: add @gameSidebar
for @selectedSidebarIndex = 1 to 3
    @selectedItemKey = 9 + @selectedSidebarIndex
    @gameSidebar(@selectedSidebarIndex) = @selectedItemKey
    @printText$ = @itemTiles$(@selectedItemKey)
    gosub writeItemSub
NEXT

# TODO: temp remove, create random pipe for item sidebar
@selectedSidebarIndex = .
@selectedItemKey = INT(RND(.) * 6) + 1
@gameSidebar(@selectedSidebarIndex) = @selectedItemKey
@printText$ = @itemTiles$(@selectedItemKey)
gosub writeItemSub

# TODO: temp remove
# draw tree, cow, and rock in random positions on the board for testing
for @selectedItemKey = 7 to 9
    @currentPlayerPostision = INT(RND(.) * 56)
    gosub writeGameBoardTileSub
next

@connectionStartPosition = INT(RND(.) * 7) * 8
@connectionEndPosition = INT(RND(.) * 7) * 8 + 7
@selectedItemKey = 13
@currentPlayerPostision = @connectionStartPosition
gosub writeGameBoardTileSub
@gameBoard(@connectionStartPosition) = .
@selectedItemKey = 14
@currentPlayerPostision = @connectionEndPosition
gosub writeGameBoardTileSub
@gameBoard(@connectionEndPosition) = .
