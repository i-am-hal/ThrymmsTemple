#[
This file has everything relating to movement, this
includes not just handling keypresses of the player,
but also the basic AI for the monsters.
Author: ALastar Slater
Date: 9/28/2019
]#


import random, terminal, strutils, strformat, playerAndObjs, floorsAndIO, monsters

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
proc roomMobMovement(floor:var Floor, player:var Player, dialog:var seq[string]) =
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

        #Default monster attack (include mimic when awake)
        elif canAttack or canAttack and mob of Mimic and (Mimic mob).awake:
            let
                chance = mob.chance    #1/chance likelyhood of hitting player
                dmg = mob.dmg          #Amount to hurt player by when hit
                hitRoll = rand(chance) #Roll if monster hit player
            
            #If attack hit, but player has armor, degrade armor
            if hitRoll == 0 and player.armor of Armor:
                #Degrade armor of the player
                (Armor player.armor).health -= (Armor player.armor).degrade
                dialog.add fmt"You were hit by a {mob.name}!" #Tell user they were hit by a monster

                #If armor just broke, tell player that their armor broke, break it
                if player.armor of Armor and (Armor player.armor).health <= 0:
                    dialog.add "Your armor broke!"
                    player.armor = GameItem(name:"None", desc:"") #Give nothing as armor
                
                else: #Otherwise, say it is degraded
                    dialog.add "Your armor degraded!" #Tell user their armor degraded

                #Redraw the player as red to show that their armor degraded
                floor.moveChar(player, '@', player.xpos, player.ypos, player.xpos, player.ypos, color=fgMagenta)
            
            #If attack hit, but player has no armor, take away health
            elif hitRoll == 0 and not (player.armor of Armor):
                player.health -= dmg #Take away this amount of health
                dialog.add fmt"You were dealt {dmg} damage by {mob.name}!" #Tell amount damaged by
                #Redraw the player as red to show that they got hurt
                floor.moveChar(player, '@', player.xpos, player.ypos, player.xpos, player.ypos, color=fgRed)
        
        #[ MONSTER MOVEMENT ]#

        #If Monster cannot move just yet, decrement speed until they can move again
        elif mob.speed > 0:
            mob.speed -= 1
        
        #Regular monster movement, move closer to attack player, reset move timer
        elif mob.speed == 0:
            floor.moveMonster(player, currRoom.mobs, mob, index, targetLocations) #Move monster in the room
            mob.speed = mob.speedRefresh   #Reset speed counter
        
        inc(index) #Increment index

#Allows player to attack monsters around them
proc playerAttack(floor:var Floor, player:var Player, dialog:var seq[string]) =
    var
        #Get the current room to get access to the monsters
        currRoom = Room (floor.floor[player.roomY][player.roomX])
        #Will hold all indexes of all monsters that will be attacked
        mobIndexes: seq[int] = @[] 

    #If this weapon from the player is some sort of melee weapon 
    if not (player.weapon of Weapon) or player.weapon of Weapon and (Weapon player.weapon).melee:
        #Get all of the areas around player to try attack surrounding monsters
        let attackAreas = spacesAroundTarget((player.xpos, player.ypos))

        #Get indexes of monsters being attacked
        for i, mob in currRoom.mobs:
            #If this is one of the attacked monsters, save index
            if mob.pos in attackAreas:
                mobIndexes.add i

    #If this is a ranged waepon, scan areas left/right, up/down of player
    elif player.weapon of Weapon and not (Weapon player.weapon).melee:
        var 
            mobX = 0 #X,Y ordinates to change for searching for target mobs
            mobY = 0
            foundMob = false #Flag for loop to say if we have found mob yet

        let 
            rightBound = len(currRoom.room[0]) - 1 #Right bound (x value for right wall)
            bottomBound = len(currRoom.room) - 1   #Lower bound (y value for bottom wall)
        
        mobX = player.xpos-1 #Setup for the search
        mobY = player.ypos
        #Search left of the player to find any mobs
        while mobX > 0 and not foundMob:
            #Go through each mob to see if they have this position
            for i, mob in currRoom.mobs:
                #If we found the mob, save index
                if mob.pos == (mobX, mobY):
                    foundMob = true  #Say we found the mob, break out
                    mobIndexes.add i #Add index of this monster
                    break            #Stop collecting monsters to attack

            dec(mobX) #Move left one more position
        
        mobX = player.xpos+1 #Setup for next search (right)
        foundMob = false     #Reset flag on if we found a mob
        #Search to the right of player to find mobs
        while mobX < rightBound and not foundMob:
            #Go through each mob for matching position
            for i, mob in currRoom.mobs:
                #if we found mob, save index
                if mob.pos == (mobX, mobY):
                    foundMob = true  #Say we found mob, break out
                    mobIndexes.add i #Add index of this monster
                    break            #Stop collecting monsters to kill

            inc(mobX) #Move right one space
        
        mobY = player.ypos-1 #Setup for search upward
        mobX = player.xpos
        foundMob = false    
        #Search upward for mobs in way
        while mobY > 0 and not foundMob:
            #Find blocking mob
            for i, mob in currRoom.mobs:
                #if found mob, save index
                if mob.pos == (mobX, mobY):
                    foundMob = true       
                    mobIndexes.add i #Save index
                    break            #Stop collecting monsters
            
            dec(mobY) #Move up
        
        mobY = player.ypos+1 #Setup for next search downward
        foundMob = false
        #Search downwards for mobs in way
        while mobY < bottomBound and not foundMob:
            #Find blocked mob
            for i, mob in currRoom.mobs:
                #Found mob, save index
                if mob.pos == (mobX, mobY):
                    foundMob = true 
                    mobIndexes.add i #Save index
                    break            #Exit loop
            
            inc(mobY) #Move down
        
    #==[ ATTACK MONSTERS, MELEE ]==#

    #Go through each monster so it can be attacked
    for index in mobIndexes:
        let mob = currRoom.mobs[index] #The current monster being attacked

        #[ CHECK IF WEAPON DIED ]#

        #If the armor has no more health, remove it, tell user about it
        if player.weapon of Weapon and (Weapon player.weapon).health <= 0:
            dialog.add "Your weapon broke!"                #Give the user the alert
            player.weapon = GameItem(name:"None", desc:"") #Remove the weapon from the player

        #[ TRY TO ATTACK THIS MONSTER ]#

        #If not an active mimic, like DON'T HURT IT
        if mob of Mimic and not (Mimic mob).awake:
            discard 0

        #If in some fasion, this is some melee weapon, use it to attack
        elif not (player.weapon of Weapon) or (Weapon player.weapon).melee:
            #If actually a weapon, try to hit monster
            if player.weapon of Weapon:
                let
                    #Get 1/chance likelyhood of hitting the monster
                    chance = (Weapon player.weapon).chance
                    #The damadge to add onto the damadge of the player
                    modifier = (Weapon player.weapon).dmg

                #If the player hit, then attack with playerDmg + weaponDmg
                if rand(chance) == 0:
                    #Allow the modifier to be a float, subtract integer amount
                    currRoom.mobs[index].health -= int(float(player.dmg) + modifier)
                    #Tells player the mob that has been struck
                    dialog.add fmt"You hit a {mob.name}" 
                
                else: #Tell player they missed
                    dialog.add fmt"You missed the {mob.name}!"

            #Deal default damadge, if no weapon equipped
            elif rand(0.. 1) == 1:
                currRoom.mobs[index].health -= player.dmg
                #Tells player the mob that has been struck
                dialog.add fmt"You hit a {mob.name}!" 
            
            else: #Tell player that they missed
                dialog.add fmt"You missed the {mob.name}!"
        
        else: #Otherwise, this is some ranged weapon
            let
                chance = (Weapon player.weapon).chance   #1/chance likelyhood of hitting
                modifier = (Weapon player.weapon).dmg    #Modifier used for dealing damadge
                degrade = (Weapon player.weapon).degrade #Amount weapon degrades by

            #If the player hits this monster, state so
            if rand(chance) == 0:
                #Deal an integer amount of damage to monster
                currRoom.mobs[index].health -= int(modifier)
                #Degrade the weapon of the player
                (Weapon player.weapon).health -= degrade
                #Tell the user what they hit
                dialog.add fmt"You hit a {mob.name}"
            
            else: #Otherwise, if you (the player) missed
                dialog.add fmt"You missed the {mob.name}"
    
#Remove all dead monsters from the room
proc removeDeadMobs(floor:var Floor, player:var Player) =
    var
        #Get the current room to get access to the monsters
        currRoom = Room (floor.floor[player.roomY][player.roomX])
        index = 0  #Index into the mobs

    #Go through each monster to check if they are dead
    while index < len(currRoom.mobs):
        let mob = currRoom.mobs[index] #get the current monster

        #Monster dead, remove it
        if mob.health <= 0:
            currRoom.mobs.delete(index) #Remove monster from room
            #Remove this monster from the room
            floor.moveChar(player, '.', mob.pos[0], mob.pos[1], mob.pos[0], mob.pos[1])
            dec(index) #Decrease index by one

        inc(index) #Move to next monster

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
                level += 1 #Go to next level
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
                level += 1  #Go to next floor
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
                level += 1  #Go to next level
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
                level += 1  #Go to next floor
                floor = newFloor() #Create the new floor
                #Spawn in the player into the floor
                floor.spawnPlayer(player, level, story)
        
    #If the player is trying to attack monsters around them
    elif key == 'q':
        actionKeyPress = true              #Say this is an action key press
        floor.playerAttack(player, dialog) #Allow the player to atack monsters around them
        floor.removeDeadMobs(player)       #Remove all dead monsters from room

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
        stdout.write " - "
        colorWrite("Shop", fgYellow) #Tell what room has a shop

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
            
            #If in range, and is Shop, use and modify shop
            elif obj.pos in targetPos and obj of Shop:
                draw = true                          #We need to refresh screen after
                var shop = Shop room.objs[obj_index] #The shop being focused on
                shopInteraction(shop, player)        #Open menu up for the shop
    
    #If player pressed key that is an 'action' that takes a 'turn'
    # then allow the monsters to move closer and/or attack
    if actionKeyPress == true:
        floor.roomMobMovement(player, dialog)

            


