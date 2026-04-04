# load the game here
# reset variables, load data, etc.

# green background
poke 53281, 5
# brown border
poke 53280, 9

print "{clr}{brown}             methane mayhem"
r1$="       {rvon}                          {rvof}       "
print r1$;
r2$="       {rvon} {rvof}                        {rvon} {rvof}       "
for i=. to 6*3
    print r2$;
next
print r1$;"{home}"
