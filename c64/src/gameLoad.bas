# load the game here

# light green background
    poke 53281, 13
# brown border
    poke 53280, 9

# draw main game board
    r1$=" {rvon}     {rvof} {rvon}                          {rvof} {91}{92}{93}{94}{95}"
    r2$="       {rvon} {rvof}                        {rvon} {rvof}"
    r3$=" {rvon} {rvof}   {rvon} {rvof} {rvon} {rvof}                        {rvon} {rvof} {rvon} {rvof}{42}{42}{42}{rvon} {rvof}"
    r4$=" {rvon} {rvof}   {rvon} {rvof} {rvon} {rvof}                        {rvon} {rvof} {rvon} {rvof}   {rvon} {rvof}"
    r5$="       {rvon}                          {rvof}"
    r6$="       {rvon}                          {rvof}"
    r7$=" {rvon}     {rvof} {rvon} {rvof}                        {rvon} {rvof} {rvon}     {rvof}"

    print "{clr}{blk}             methane mayhem"
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

gosub generateLevelSub

# fill the timer
    @timer = 0
    @printText$ = "{rvon}{yellow}   {rvof}"
    x = 2
    for y = 17 to 2 step -1
        gosub writeTextSub
        @timer = @timer + 1
    next
