# Start sprite writing

# Sprite data must live in RAM inside the active VIC bank.
# Using 51200 ($C800) keeps it in Bank 3 and avoids VIC register space at $D000.
for i=51200 to 51262
    read c
    poke i,c
next

# Sprite number from 1 to 7
for sn=. to 1
    # Sprite 0 pointer is at screen_base+1016 (52224+1016=53240).
    # Pointer value is offset/64 from VIC bank start: (51200-49152)/64 = 32.
    poke 53240+sn, 32

    # Enable sprite 0 (bit 0 of $D015 / 53269).
    poke 53269, peek(53269) or (2^sn)

    # For resizing the sprite
    # x double-width on
    poke 53277, peek(53277) or (2^sn)
    # y double-height on
    poke 53271, peek(53271) or (2^sn)
next
