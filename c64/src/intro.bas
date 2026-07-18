# into or title screen
print "{clr}welcome to the game!"
print "press return to begin"
for i = . to 2000
    get @keyInput$
    if @keyInput$ <> "" then if ASC(@keyInput$) = 13 then i = 2000 : goto introLoopDone
    if i >=2000 then i = .
    introLoopDone:
next
