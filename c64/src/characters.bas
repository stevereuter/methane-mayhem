# Start custom characters writing
x = x + 1
on x goto loadCharacterSet, discLoadingComplete

loadCharacterSet:
    # Switch VIC to Bank 3
    poke 56576, peek(56576) and 252

    # Set Screen to 52224 and Chars to 49152
    poke 53272, 48

    # Tell BASIC the screen moved
    poke 648, 204

    #include "splash.bas"
    # load characterset from disk
    load "chars", 8, 1

discLoadingComplete:
