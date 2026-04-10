# subroutines.bas
# write tx$ to x,y
writeTextSub:
    poke 211, x
    poke 214, y
    sys 58732
    print tx$;
return
