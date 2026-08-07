# functions
def fn @checkGameState(@state) = (@gameState and @state) = @state
def fn @addGameState(@state) = @gameState or @state
def fn @removeGameState(@state) = @gameState and (not @state)

# variables
# start with the most important ones in the main game loop
let x = .
let y = .
# game board types
let @empty = .
let @pipeUp = 1
let @pipeRight = 2
let @pipeDown = 4
let @pipeLeft = 8
let @growing = 16
let @tree = 32
let @rock = 64
# effects, 
let @burning = 128
let @cow = 256
let @invincible = 512
let @destroy = 1024
let @move = 2048
let @rotate = 4096
let @large = 8192
let @explosion = @destroy + @large
# not usable = 16384
# NOTE: there is no 16th bit as that is used for the sign in C64 BASIC
# NOTE: the idea here being that an item would contain the affected type and effect, so the giddy up would be 2048+16 (move cow), the axe would be 1024+32 (destroy tree), and the cone would be 4096+16+32 (blocked cow and tree)

let i = .
let r = .
let @checkIndex = .
let @nextIndex = .
let @checkTile = .
let @requiredConnection = .
let @column = .
let @connectionStartPosition = .
let @connectionEndPosition = .
let @selectedItemKey = .
let @selectedItem = .
let @previousItem = .
let @newItem = .

let @gameLoop = .
let @currentPlayerPostision = .
let @selectedSidebarIndex = .
let @direction = .
let @nextItemKey = .
let @nextValue = .
let @drawTo = .
let @clearTo = .
let @moved = .
let a = .
let b = .
let c = .
let @ufoTarget = -1
let @toolCount = .
let @startX = 88
let @startY = 66

# game states
let @level = 1
let @gameState = .
let @gameStateLeaking = 1
let @gameStatePanicing = 2
let @gameStateMeteor = 4
let @gameStateUfoAbduction = 8
let @gameStateAlienInvasion = 16
let @gameStateComplete = 32
let @gameStateOver = 64
let @gameStateChallengeMode = 128

let @printText$ = ""
let @loopMax = 100
let @feeder$ = ""
let @timer = 15
let @seed = .
# starting registers for sprite 0
let @spriteReg = 53240
let @spriteRegX = 53248
let @spriteRegY = 53249
let @spriteColor = 53287
let @currentSprite = .
# sprite flags, bit for each sprite
let @spritesEnabled = 53269
let @spriteDoubleX = 53277
let @spriteDoubleY = 53271
let @spriteScreenRight = 53264
# sprite date pointers starting at 51200 (x-49152)/64 = y
let @spriteSelector = 32
let @spriteMeteor = 33
# let @spriteMeteor2 = 34
let @spriteFire = 35
# let @spriteFire2 = 36
let @spriteTreeGrow = 37
# let @spriteTreeGrow2 = 38
let @spriteUFO = 39
let @spriteBeam = 40
# let @spriteBeam2 = 41
let @spriteDestroy = 42
# let @spriteDestroy2 = 43
# let @spriteDestroy3 = 44
let @spriteGas = 45
#let @spriteGas2 = 46
let @spriteCow = 47
# animation variables
let @burnAnimation = .

# arrays
dim @colorPulse(6)
# game board, 8x7 grid for 56 total cells
dim @gameBoard(56)
dim @gameSidebar(4)
# items
dim @itemValues(20)
# board tiles
dim @itemTiles$(20)
# explotion positions
dim @explosionPositions(5)

dim @levelItems(4)
@levelItems(0) = 8
@levelItems(1) = 7
@levelItems(2) = 9
@levelItems(3) = 20

dim @levelTools(7)
@levelTools(0) = 15
@levelTools(1) = 16
@levelTools(2) = 10
@levelTools(3) = 12
@levelTools(4) = 11
@levelTools(5) = 18
@levelTools(6) = 19

@colorPulse(0) = 1
@colorPulse(1) = 15
@colorPulse(2) = 12
@colorPulse(3) = 11
@colorPulse(4) = 12
@colorPulse(5) = 15

# all item images
# empty
    @itemTiles$(0) = "   {down}{3 left}   {down}{3 left}   "
    @itemValues(0) = @empty
# pipe vertical
    @itemTiles$(1) = "{brn} {36} {down}{3 left} {36} {down}{3 left} {36} "
    @itemValues(1) = @pipeUp + @pipeDown
# pipe horizontal
    @itemTiles$(2) = "{brn}   {down}{3 left}{35}{35}{35}{down}{3 left}   "
    @itemValues(2) = @pipeLeft + @pipeRight
# pipe corner down right
    @itemTiles$(3) = "{brn}   {down}{3 left} {221}{35}{down}{3 left} {36} "
    @itemValues(3) = @pipeDown + @pipeRight
# pipe corner down left
    @itemTiles$(4) = "{brn}   {down}{3 left}{35}{64} {down}{3 left} {36} "
    @itemValues(4) = @pipeDown + @pipeLeft
# pipe corner up right
    @itemTiles$(5) = "{brn} {36} {down}{3 left} {37}{35}{down}{3 left}   "
    @itemValues(5) = @pipeUp + @pipeRight
# pipe corner up left
    @itemTiles$(6) = "{brn} {36} {down}{3 left}{35}{38} {down}{3 left}   "
    @itemValues(6) = @pipeUp + @pipeLeft
# tree
    @itemTiles$(7) = "{green}{192}{193}{194}{down}{3 left}{208}{209}{210}{down}{3 left}{lightgreen}{160}{161}{162}"
    @itemValues(7) = @tree
# cow
    @itemTiles$(8) = "{brn}{195}{196}{32}{down}{3 left}{211}{212}{213}{down}{3 left}{blk}{163}{brn}{164}{165}"
    @itemValues(8) = @cow
# rock
    @itemTiles$(9) = "{brn}{198}{199}{200}{down}{3 left}{214}{215}{216}{down}{3 left}{166}{167}{168}"
    @itemValues(9) = @rock
# giddy up
    @itemTiles$(10) = "{grn}{201}{brn}{202}{grn}{203}{down}{3 left}{brn}{217}{218}{white}{219}{down}{3 left}{grn}{169}{brn}{170}{grn}{171}"
    @itemValues(10) = @move + @cow
# pick axe
    @itemTiles$(11) = "{white}{61}{62}{63}{down}{3 left}{blk}{43}{60}{white}{207}{down}{3 left}{blk}{175}{44}{white}{223}"
    @itemValues(11) = @destroy + @rock
# axe
    @itemTiles$(12) = "{white}{32}{58}{59}{down}{3 left}{blk}{43}{60}{white}{183}{down}{3 left}{blk}{175}{44}{32}"
    @itemValues(12) = @destroy + @tree
# start
    @itemTiles$(13) = "{brn}   {down}{4 left}{35}   {down}{3 left}   "
    @itemValues(13) = .
# end
    @itemTiles$(14) = "{brn}   {down}{3 left}   {35}{down}{4 left}   "
    @itemValues(14) = .
# rotate right
    @itemTiles$(15) = "{grn}{204}{173}{206}{down}{3 left}{222}{32}{220}{down}{3 left}{172}{205}{174}"
    @itemValues(15) = @rotate + @pipeRight
# rotate left
    @itemTiles$(16) = "{grn}{204}{205}{206}{down}{3 left}{220}{32}{222}{down}{3 left}{172}{173}{174}"
    @itemValues(16) = @rotate + @pipeLeft
# baby tree
    @itemTiles$(17) = "{3 32}{down}{3 left}{3 32}{down}{3 left}{32}{lightgreen}{176}{32}"
    @itemValues(17) = @tree + @growing
# match
    @itemTiles$(18) = "{32}{blk}{43}{red}{177}{down}{3 left}{blk}{43}{60}{44}{down}{3 left}{175}{44}{32}"
    @itemValues(18) = @tree + @burning
# dynamite
    @itemTiles$(19) = "{32}{red}{181}{lightgrey}{182}{down}{3 left}{red}{181}{179}{180}{down}{3 left}{178}{180}{32}"
    @itemValues(19) = @destroy + @large
# alien cow
    @itemTiles$(20) = "{grey}{195}{196}{32}{down}{3 left}{211}{212}{213}{down}{3 left}{blk}{163}{grey}{164}{165}"
    @itemValues(20) = @cow + @invincible
