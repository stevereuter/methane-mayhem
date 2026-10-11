Methane Mayhem
(c) 2026 Steviesaurus Dev
steviesaurus-dev.itch.io/

Introduction
Methane Mayhem is a puzzle game written in BASIC where you have to complete a connection between two points using random pipe sections. It's a turn based game with 5 time limit levels.

Layout
The screen is split into 3 sections:
Left - timer
Middle - main board
Right - items

Controls
Your position is shown on the main board with a flashing indicator of the currently selected item. You use the joystick in port 2 to move the around the board, and press fire to use or place the current item. To change current item go all the way to the right, off of the board, into the item section. From here use up and down the change item, then go left to go back to the board.

Timer
The left side of the screen contains a timer. The time will start full, indicating the time remaining until methane is released, and drop on each turn. Once at the bottom, methane will start to leak from the left side connection. Now the timer will start to refill on each turn until it reaches the top. Once at the top, too much methane has leaked and the level will end.

Main Board
The objective of each level is to complete a connect between two pipes on the left and the right sides of the board. The vertical position of these is random. You will have to place randomly generated sections of pipe across the board to complete the connection. There are also obstacles on the board that may have to be worked around or removed in order to complete the connection.
- cows: will move through empty spaces on the board
- trees: can spawn on each turn but only block the space once grown
- rocks: can be spawned by a meteor (level 2 and up)
- alien cows: can be spawned by an alien invasion and can move to any space on the board destroying what it replaces (level 3 and up)

Tools
The tolls section is split into two parts. At the top is a single pipe section that shows what will be available on the next turn. Below that is the main area with 4 items. At the top is the pipe section that is currently available to place on the board. The 3 items below that are tools that can be used. Each tool has a specific use and can only be used once. Once all 3 tools are used, the section will refill with 3 new randomly generated tools.
- rotate left or right: use to rotate a section of pipe
- giddy up: use to move a cow in a random diagonal direction
- axe: removes a tree
- match: takes 1 turn to remove a tree and creates panic
- pick axe: removes a rock
- dynamite: removes a rock but also removes anything in the 4 adjacent spaces and causes panic

Events
Some events never change, such as tree spawn percent, while others will increase based on the level. Not all events can happen on all levels.
- tree spawn: 50% all levels
- cow movement 30% all levels, 100% when panicked (if movement is possible and not skipped)
- meteor, alien abduction, and alien invasion are all 10% x level
- meteor: level 2 and up
- alien abduction: level 3 and up, will trigger 100% alien invasion on next turn
- alien invasion: level 4 and up

Story
Jodel and Jayleen Farmer are the perfect siblings, and can accomplish anything together, but without each other they struggle. After inheriting the failing family farm, Jaleen finds two unlikely sources to help turn their lives around.
Jayleen read an article about the struggles that MAD (Mars Accommodation Realtors) were having difficulties selling homes on Mars due to cold it is. To encourage buyers they are now attempting to change the atmosphere with increased greenhouse gasses to warm things up a little. Meanwhile, EWOC (Environmental Workers Organization Corperation) are struggling to lower the greenhouse effect on Earth which is increasing the global natural disasters. Jaleen, being the smart one, came up with a blueprint for a device that could extract  greenhouse gasses, such as methane, from the air. She named it the Farmers Air Reclaimer Technology, or FART for short, and handed to to Jodel, the mechanical one, to build it.
With their FART ready to go, they reached out to MAD EWOCs for funding. The MAD ones said that they would gladly purchase the FART gases, so that they could release them on Mars, but would need the FART gasses delivered using a pipe network. EWOCs also wanted to help and would give bonuses as long as no other environmental issues occurred in the process.
Once Jaleen started her FART, it became clear that it was very effective, and they would need the pipeline build fast. Once again Jodel jumped in and started producing FART pipes at an amazing rate, but unfortunately there was no logic behind the parts that he was building, and Jaleen didn't have time to set him straight. So she now has to use that brain of hers to quickly connect all the random sections as best she can before FART gasses are leaking back into the environment.
