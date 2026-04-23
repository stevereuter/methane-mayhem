# subroutines.bas

# write tx$ to x,y
writeTextSub:
    poke 211, x
    poke 214, y
    sys 58732
    print tx$;
return

# write to game board convert index bi to x,y
writeGameBoardTileSub:
    x=8 + int(bi/7)*3
    y=2 + int(bi/7)*3
    gosub writeTextSub
return
