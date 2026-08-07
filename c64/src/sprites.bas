# sprite data is loaded into memory from disc
# 0: meteor/UFO (movement, multi color)
# 1: tool selector (on board, color cycle)
# 2: player position (on board, color cycle)
# 3: UFO beam/tree grow (2 frame)
# 4: removal poof (2 frame)
# 5: cow (movement)
# 6: methane leak (on board, 2 frame)
# 7: fire (on board, 2 frame)
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
# set fire sprite to yellow
poke @spriteColor + 7, 7
