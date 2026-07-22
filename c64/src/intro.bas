# into or title screen
@seed = .
print "{clr}methane mayhem!"
print "use AWSD to move your position"
print "use 1-4 to select items"
print "press return to place the item"
print "press l to set the challenge mode seed"
print "press return to begin"

for i = . to 2000
    get @keyInput$
    if @keyInput$ <> "" then if ASC(@keyInput$) = 13 then i = 2000 : goto introLoopDone
    if @keyInput$ = "l" then @isChallengeMode = -1 : gosub generateSeedSub : i = 2000 : goto introLoopDone
    if i >=2000 then i = .
    introLoopDone:
next
