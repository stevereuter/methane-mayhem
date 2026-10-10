# Start custom characters writing
x = x + 1
on x goto loadSplashScreen, loadSplashScreenChars, loadSplashScreenColors, loadCharacterSet, loadSprites, discLoadingComplete

# load splash screen memory
loadSplashScreen:
    load "screen", 8, 1

# load splash screen characters
loadSplashScreenChars:
    print "{clr}"
    poke 53281, 13
    poke 53280, 9
    # Switch VIC to Bank 2
    poke 56576, (peek(56576) and 252) or 1
    # switch to multi color mode
    poke 53272, 222
    # set shared 1 color
    poke 53282, 11
    # set shared 2 color
    poke 53283, 1
    # Set screen block 13 and char block 7
    poke 53270, peek(53270) or 16
    load "splash", 8, 1

# load splash screen colors
loadSplashScreenColors:
    load "color", 8, 1

loadCharacterSet:
    # load characterset from disk
    load "chars", 8, 1

loadSprites:
    # load sprites from disk
    load "sprites", 8, 1

discLoadingComplete:
    # Switch VIC to Bank 3
    poke 56576, peek(56576) and 252

    # Set Screen to 52224 and Chars to 49152
    poke 53272, 48

    # set shared color 1
    poke 53282, 15
    poke 53285, 15
    # set shared color 2
    poke 53283, 0
    poke 53286, 0

    # Tell BASIC the screen moved
    poke 648, 204
