# sprite data is loaded into memory from disc
# | id | bit | value | description
# | 0  | 1   | 1   | meteor/UFO (movement, multi color)
# | 1  | 2   | 2   | tool selector (on board, color cycle)
# | 2  | 3   | 4   | player position (on board, color cycle)
# | 3  | 4   | 8   | UFO beam/tree grow (2 frame)
# | 4  | 5   | 16   | removal poof (2 frame)
# | 5  | 6   | 32   | cow (movement)
# | 6  | 7   | 64   | methane leak (on board, 2 frame)
# | 7  | 8   | 128  | fire (on board, 2 frame)
# Sprite number from 1 to 7
for sn = 1 to 2
    # Sprite 0 pointer is at screen_base+1016 (52224+1016=53240).
    # Pointer value is offset/64 from VIC bank start: (51200-49152)/64 = 32.
    poke @spriteReg + sn, @spriteSelector

    # Enable sprite 0 (bit 0 of $D015 / 53269).
    # poke 53269, peek(53269) or (2 ^ sn)

    # For resizing the sprite
    # x double-width on
    poke @spriteDoubleX, peek(@spriteDoubleX) or (2 ^ sn)
    # y double-height on
    poke @spriteDoubleY, peek(@spriteDoubleY) or (2 ^ sn)
next
# set colors
poke @spriteColor + 7, 7
poke @spriteColor + 5, 1
poke @spriteColor, 2
poke @spriteColor + 6, 6
# set sprites 0 and 5 to multi-color mode
poke 53276, 33

poke @spriteReg, @spriteUFO
