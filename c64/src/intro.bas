# into or title screen
@seed = .
print "{clr}{blk}methane mayhem!" ; spc(2) ; "by steviesaurus dev" : print
print "warning! this game is currently in      development. feel free to report bugs or suggestions in the devlog comments     related to version v{version}. "
print "thank you." : print
print "use the joystick to move in the map" : print
print "go all the way to the right to select   the pipe or tool" : print
print "press fire to place the pipe/tool" : print
print "press right to use the challenge mode   then enter a seed value" : print
print "press fire to begin"

@gameState = fn @removeGameState(@gameStateChallengeMode)

for i = . to 2000
    gosub joystickInputHandlerSub
    if @fireOn then i = 2000 : goto introLoopDone
    if @directionRight then @gameState = fn @addGameState(@gameStateChallengeMode) : i = 2000 : goto introLoopDone
    if i >=2000 then i = .
    introLoopDone:
next

@level = 1
gosub generateSeedSub
@catastrophePercent = @level / 10
