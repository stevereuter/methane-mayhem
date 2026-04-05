# load the game here
# reset variables, load data, etc.

# light green background
poke 53281, 13
# brown border
poke 53280, 9

print "{clr}{brown}             methane mayhem"
r1$="       {rvon}                          {rvof}"
print r1$
r2$="       {rvon} {rvof}                        {rvon} {rvof}"
r3$="       {rvon} {rvof}                        {rvon} {rvof} {rvon}     {rvof}"
r4$="       {rvon} {rvof}                        {rvon} {rvof} {rvon} {rvof}   {rvon} {rvof}"

for i=. to 2
    print r2$
next
print r3$
for i=. to 11
    print r4$
next
print r3$
for i=. to 3
    print r2$
next

print r1$;
