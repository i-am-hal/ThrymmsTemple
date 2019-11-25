#[
This file has everything relating to movement, this
includes not just handling keypresses of the player,
but also the basic AI for the monsters.
Author: ALastar Slater
Date: 9/28/2019
]#


import random, terminal, strutils, playerAndObjs, floorsAndIO, monsters

#Checks if there is a character in a certain direction
proc checkChar(room:Room, x, y: int, chr: char, modX=0,modY=0): bool =
    y+modY >= 0 and y+modY < len(room.room) and x+modX >= 0 and
    x+modX < len(room.room[y+modY]) and room.room[y+modY][x+modX] == chr

#If there is an empty place to the left
proc leftEmpty(room:Room, x, y:int): bool = checkChar(room, x, y, '.', modX= -1)

#If there is a door to the left 
proc leftDoor(room:Room, x, y:int): bool = checkChar(room, x, y, 'D', modX= -1)

#If there is a staricase to the left
proc leftStair(room:Room, x, y:int): bool = checkChar(room, x, y, '^', modX= -1)

#Check if the spot above the given coordenates is empty
proc upEmpty(room:Room, x, y:int): bool = checkChar(room, x, y, '.', modY= -1)

#Check if there is a door above this spot
proc upDoor(room:Room, x, y:int): bool = checkChar(room, x, y, 'D', modY= -1)

#Check if there is a door above this point
proc upStair(room:Room, x, y:int): bool = checkChar(room, x, y, '^', modY= -1)

#Check if the spot the right is empty
proc rightEmpty(room:Room, x, y:int): bool = checkChar(room, x, y, '.', modX=1) 

#Check if there is a door to the right
proc rightDoor(room:Room, x, y:int): bool = checkChar(room, x, y, 'D', modX=1)

#Check if there is a staircase to the right
proc rightStair(room:Room, x, y:int): bool = checkChar(room, x, y, '^', modX=1)

#Check if the spot below the coordinates is empty space
proc downEmpty(room:Room, x, y:int): bool = checkChar(room, x, y, '.', modY=1)

#Check if there is a door below the coordinates given
proc downDoor(room:Room, x, y:int): bool = checkChar(room, x, y, 'D', modY=1)

#Check if there is a staircase downward
proc downStair(room:Room, x,y:int): bool = checkChar(room, x, y, '^', modY=1)

#Moves the monster left/right or up/down based on the unit movement vector
proc moveMonster(floor:var Floor, player:var Player, allMobs:seq[Monster], mob:Monster, mobIndex:int, targets:seq[(int, int)]) =
    var 
        moveVector = getMoveVector(allMobs, mob.pos, targets) #Get movement vector of this monster
        room = Room (floor.floor[player.roomY][player.roomX]) #The current room used for seeing empty spaces
    
    #If not a simple vector, turn it into one
    if not simpleVec(moveVector):
        let chooseX = rand(0.. 1) #Pick if we simplify x

        #If we are eliminating the x, do so
        if chooseX == 1:
            moveVector[0] = 0
        
        else: #Eliminate the y coordinates otherwise
            moveVector[1] = 0

    let
        moveX = moveVector[0] #The individual x-y coorindates
        moveY = moveVector[1]
        x = mob.pos[0] #X-y coordinates currently of monster
        y = mob.pos[1]

    #If no need to move in the x-axis, move in y 
    if moveX == 0 and moveY != 0:
        #If the right/left is totally clear, move there
        if moveY > 0 and room.downEmpty(x, y) or moveY < 0 and room.upEmpty(x, y):
            room.mobs[mobIndex].pos[1] += moveY                              #Save the new y position
            floor.moveChar(player, mob.chr, x, y, x, y + moveY, color=fgRed) #Move monster in the room
        
        #If the space above is empty, move up
        elif room.leftEmpty(x, y):
            room.mobs[mobIndex].pos[0] -= 1                              #Make monster move left
            floor.moveChar(player, mob.chr, x, y, x - 1, y, color=fgRed) #Move monster in the room
        
        #If the space below is empty, move down
        elif room.rightEmpty(x, y):
            room.mobs[mobIndex].pos[0] += 1                              #Make monster move right
            floor.moveChar(player, mob.chr, x, y, x + 1, y, color=fgRed) #Move monster in the room
    
    #If no need to move in the y-axis, move in x 
    elif moveX != 0 and moveY == 0:
        #If the monster can move left or right, do so
        if moveX > 0 and room.rightEmpty(x, y) or moveX < 0 and room.leftEmpty(x, y):
            room.mobs[mobIndex].pos[0] += moveX                         #Save the new x position
            floor.moveChar(player, mob.chr, x, y, x + moveX, y, color=fgRed) #Move monster in room
        
        #If the space above is empty, move there
        elif room.upEmpty(x, y):
            room.mobs[mobIndex].pos[1] -= 1                              #Make monster move up
            floor.moveChar(player, mob.chr, x, y, x, y - 1, color=fgRed) #Move monster in room
        
        #If the space below is empty, move there
        elif room.downEmpty(x, y):
            room.mobs[mobIndex].pos[1] += 1                              #Make monster move right
            floor.moveChar(player, mob.chr, x, y, x, y + 1, color=fgRed) #Move monster in room

#This deals with the movement / actions of all mobs in the room
proc roomMobMovement(floor: var Floor, player:var Player) =
    var 
        #The current room being modified
        currRoom = Room (floor.floor[player.roomY][player.roomX])
        index = 0 #The index of the current monster

    #Go through each mob and have it either move, or attack
    for mob in currRoom.mobs:
        let
            #Get the target locations of this monster
            targetLocations = mob.getTargetLocations((player.xpos, player.ypos))
            canAttack = mob.pos in targetLocations #If monster in target locations (i.e. can attack)
        
        #If this is a mimic, if it isn't awake and can attack, become active
        if mob of Mimic and not (Mimic mob).awake and canAttack:
            (Mimic mob).awake = true  #Make the mimic active
            (Mimic mob).chr = 'm'     #Chance character to lowercase m
            let pos = (Mimic mob).pos #Get position of mimic
            #Draw in character again in red but as an 'm'
            floor.moveChar(player, 'm', pos[0], pos[1], pos[0], pos[1], color=fgRed)
        
        #Stop mimics from moving until they have been awakened
        elif mob of Mimic and not (Mimic mob).awake and not canAttack:
            #Do literally nothing
            discard 0
        
        #[ MONSTER ATTACK ]#
        
        #[ MONSTER MOVEMENT ]#

        #If Monster cannot move just yet, decrement speed until they can move again
        elif mob.speed > 0:
            mob.speed -= 1
        
        #Regular monster movement, move closer to attack player, reset move timer
        elif mob.speed == 0:
            floor.moveMonster(player, currRoom.mobs, mob, index, targetLocations) #Move monster in the room
            mob.speed = mob.speedRefresh   #Reset speed counter
        
        inc(index) #Increment index


#Deals with whatever action is associated with a keypress in the game
proc handleKeypress*(keypress:char, dialog:var seq[string], player:var Player, floor:var Floor, done, draw:var bool, level:var int, story:bool) =
    let key = keypress.toLowerAscii() #Make the current char lowercase
    #Get the current room to be looked at
    let room = Room (floor.floor[player.roomY][player.roomX])

    #Say last key (DEBUGGING)
    #stdout.setCursorPos(30,1)
    #stdout.write("LAST KEY: " & key)

    #If an action key was pressed: w,a,s,d,q
    # (then monsters will be allowed to move)
    var actionKeyPress = false

    #If this is movement for player
    if key in "wasd":
        #Mark that we had an action key press
        actionKeyPress = true

        #Moving up, check if theres a door, or empty space
        if key == 'w':
            #If there is an empty space, move up
            if upEmpty(room, player.xpos, player.ypos):
                #Move the player on screen up one space
                floor.moveChar(player, '@', player.xpos, player.ypos, player.xpos, player.ypos-1, color=fgCyan)
                player.ypos -= 1 #Make the player move up one space
            
            #IF there is a door above, enter new room
            elif upDoor(room, player.xpos, player.ypos) and player.roomY > 0:
                actionKeyPress = false #Don't move monsters
                draw = true #Tell program to draw new room
                player.roomY -= 1 #Move up one room
                #Move player into new room
                floor.enterRoom(player, player.roomX, player.roomY+1, 3, level, story)
            
            #If there is a staircase above, go to next floor
            elif upStair(room, player.xpos, player.ypos):
                actionKeyPress = false #Don't move monsters
                inc level #Go to next level
                draw = true #Say we need to draw new room
                floor = newFloor() #Make a new floor
                floor.spawnPlayer(player, level, story) #Spawn player in  new room
        
        #If moving left check if there is a door or open space
        elif key == 'a':
            #If there is an open space, move there
            if leftEmpty(room, player.xpos, player.ypos):
                #Move player on screen left one space
                floor.moveChar(player, '@', player.xpos, player.ypos, player.xpos-1, player.ypos, color=fgCyan)
                player.xpos -= 1 #Save change in x position
            
            #If there is a door to the left, move to the next room
            elif leftDoor(room, player.xpos, player.ypos):
                actionKeyPress = false #Don't move monsters
                draw = true #Say we will draw the room
                player.roomX -= 1 #Move to room to the left
                #Move into the corresponding room
                floor.enterRoom(player, player.roomX+1, player.roomY, 2, level, story)
            
            #If there is a staircase left, ascend a floor
            elif leftStair(room, player.xpos, player.ypos):
                actionKeyPress = false #Don't move monsters
                draw = true #Draw the new room
                floor = newFloor() #Make a new floor
                floor.spawnPlayer(player, level, story) #Spawn in the player
            
        #Move right, check if there is a door or empty space
        elif key == 'd':
            #If there is an empty space, move there
            if rightEmpty(room, player.xpos, player.ypos):
                #Move player right one space
                floor.moveChar(player, '@', player.xpos, player.ypos, player.xpos+1, player.ypos, fgCyan)
                player.xpos += 1 #Save change in x
            
            #If there is a door to the right, enter room
            elif rightDoor(room, player.xpos, player.ypos):
                actionKeyPress = false #Don't move monsters
                draw = true #Draw in the next room
                #Move us to the room to the right
                player.roomX += 1
                #Enter from the left
                floor.enterRoom(player, player.roomX-1, player.roomY, 4, level, story)
            
            #If there is a stair to the right, ascend a floor
            elif rightStair(room, player.xpos, player.ypos):
                actionKeyPress = false #Don't move monsters
                draw = true #Draw in the new room
                floor = newFloor() #Create the new floor
                #Spawn in the player
                floor.spawnPlayer(player, level, story)
            
        #Move down, check for door or empty space
        elif key == 's':
            #If there is empty spot, move down
            if downEmpty(room, player.xpos, player.ypos):
                #Show movement
                floor.moveChar(player, '@', player.xpos, player.ypos, player.xpos, player.ypos+1, fgCyan)
                player.ypos += 1 #Save change in y
            
            #Enter the new room from the north
            elif downDoor(room, player.xpos, player.ypos):
                actionKeyPress = false #Don't move monsters
                draw = true #Draw the next room in
                player.roomY += 1 #Move down one room
                #Enter the room
                floor.enterRoom(player, player.roomX, player.roomY-1, 1, level, story)
            
            #If there is a staircase downward, create new floor
            elif downStair(room, player.xpos, player.ypos):
                actionKeyPress = false #Don't move monsters
                draw = true #Draw in the new room
                floor = newFloor() #Create the new floor
                #Spawn in the player into the floor
                floor.spawnPlayer(player, level, story)
        
    #The player opening up a map
    elif key == 'm':
        draw = true #Redraw room after
        stdout.eraseScreen() #Clear the screen

        stdout.setCursorPos(0,0)
        stdout.write("ESC to exit) ")

        stdout.setCursorPos(0,1) #Set position to 0,0
        colorWrite("Explored", fgWhite)
        stdout.write " - "
        colorWrite("Exit", fgGreen) #Tell which is an exit

        drawMap(floor) #Draw out the map for the user

        var chr = '\0' #Temp. var

        #Wait until player enters esc character
        while chr != '\x1b':
            chr = getch()
    
    #If the player is using a health potion
    elif key == 'f':
        #If has potions, and gained health <= 100, just add 5
        if player.potions > 0 and player.health + 5 <= 100:
            player.health += 5  #Add some health to the player
            player.potions -= 1 #Subtract a potion

        #Tell player that they are at full health
        elif player.potions > 0 and player.health == 100:
            dialog.add "You are at full health!"
        
        #If has potions, and gained health > 100, make health 100
        elif player.potions > 0 and player.health + 5 > 100:
            player.health = 100 #Set player to max health
            player.potions -= 1 #Remove a potion
        
        else: #No potions
            dialog.add "You don't have potions!"

    #If the player is wanting to look at their inventory
    elif key == 'i':
        draw = true              #Mark that we must redraw everything
        player.playerInventory() #Open the inventory for the player

    #Interact with any shop keeps / open chests
    elif key == 'e' and len(room.objs) > 0:
        let
            #Get the position of the player so we can check surrounding areas around player
            targetPos =
                #Spots left and right of player and above + below player
                @[(player.xpos-1, player.ypos), (player.xpos+1, player.ypos),
                (player.xpos, player.ypos-1), (player.xpos, player.ypos+1)]

        #Go through each object to get those within range
        for obj_index in 0 .. high(room.objs):
            let obj = room.objs[obj_index] #Get object to check if this is in range

            #If in range, and is chest, open and modify the chest
            if obj.pos in targetPos and obj of Chest:
                draw = true                            #Note to redraw the room
                var chest = Chest room.objs[obj_index] #The currently focused on chest
                openChest(chest, player)               #Opens the chest
    
    #[ MONSTER ACTIVITY ]#

    #If player pressed key that is an 'action' that takes a 'turn'
    # then allow the monsters to move closer and/or attack
    if actionKeyPress == true:
        floor.roomMobMovement(player)

            


