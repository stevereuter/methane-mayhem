# into or title screen
@seed = .
print "{clr}"
x = 1 : y = 1 : gosub locateCursorSub : print @itemTiles$(8);
x = 35 : gosub locateCursorSub : print @itemTiles$(8);
x = 5 : y = 1 : gosub locateCursorSub
print "{rvon}{grey}{196}{197}{198}{199}{200}{201}{202}{203}{204}{205}{206}{207}{198}{199}{rvof}  {rvon}{196}{197}{204}{205}{218}{219}{202}{203}{198}{199}{196}{197}" 
y = 2 : gosub locateCursorSub
print "{rvon}{grey}{212}{213}{214}{215}{purple}{216}{blk}{217}{grey}{212}{213}{220}{221}{222}{223}{214}{215}{rvof}  {rvon}{212}{213}{220}{221}{purple}{216}{blk}{217}{grey}{212}{213}{214}{215}{212}{213}"

x = 1 : y = 6 : gosub locateCursorSub
print "{blk}connect the pipes on each side to"
print " complete the levels." : print
print " use the tools to clear obstacles."

y = 11
for x = 0 to 9 step 3
    gosub locateCursorSub : print @itemTiles$(2);
next
x = 17 : gosub locateCursorSub : print @itemTiles$(12);
x = 20 : gosub locateCursorSub : print @itemTiles$(7);
for x = 28 to 37 step 3
    gosub locateCursorSub : print @itemTiles$(2);
next

x = 1 : y = 14 : gosub locateCursorSub
print "{blk}{rvon}{194}{195}"
print " {rvon}{210}{211}{rvof} press fire to begin"
print " {rvon}{226}{227}"
print " {rvon}{192}{193}"
print " {rvon}{208}{209}{rvof} press right for challenge mode"
print " {rvon}{224}{225}"
x = 11 : y = 22 : gosub locateCursorSub : print "joystick in port 2" : print
x = 4 : y = 24 : gosub locateCursorSub : print "steviesaurus-dev.itch.io  v{version}";

@gameState = fn @removeGameState(@gameStateChallengeMode)
gosub joystickResetSub
for i = . to 2000
    gosub joystickInputHandlerSub
    if @fireOn then i = 2000 : goto introLoopDone
    if @directionRight then @gameState = fn @addGameState(@gameStateChallengeMode) : i = 2000 : goto introLoopDone
    if i >=2000 then i = .
    introLoopDone:
next
