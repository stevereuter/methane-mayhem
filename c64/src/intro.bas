# into or title screen
@seed = .
print "{clr}{blk}methane mayhem!" ; spc(2) ; "by steviesaurus dev" : print
print "warning! this game is currently in      development. feel free to report bugs or suggestions in the devlog comments     related to version v{version}. "
print "thank you." : print
print "use wasd to move in the map" : print
print "use 1-4 to select pipe/tool" : print
print "press return to place the pipe/tool" : print
print "press l to set the challenge mode seed" : print
print "press return to begin"

@gameState = fn @removeGameState(@gameStateChallengeMode)

for i = . to 2000
    get @keyInput$
    if @keyInput$ <> "" then if ASC(@keyInput$) = 13 then i = 2000 : goto introLoopDone
    if @keyInput$ = "l" then @gameState = fn @addGameState(@gameStateChallengeMode) : gosub generateSeedSub : i = 2000 : goto introLoopDone
    if i >=2000 then i = .
    introLoopDone:
next
