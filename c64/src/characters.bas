# Start custom characters writing
# Switch VIC to Bank 3
poke 56576, peek(56576) and 252

# Set Screen to 52224 and Chars to 49152
poke 53272, 48

# Tell BASIC the screen moved
poke 648, 204

print "{clr}methane mayhem v###VERSION### c64"
print "{down}(c)2026 steviesaurus dev"
print "{down}steviesaurus-dev.itch.io"

# add custom characters from data.bas
for i=49152 to 49152+(256*8)-1
    read c
    poke i,c
next
