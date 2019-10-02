#[
This file has everything relating to movement, this
includes not just handling keypresses of the player,
but also the basic AI for the monsters.
Author: ALastar Slater
Date: 9/28/2019
]#


import player, floorsAndIO, terminal

#Checks if there is a character in a certain direction
proc checkChar(room:Room, x, y: int, chr: char, modX=0,modY=0): bool =
    y+modY >= 0 and y+modY < len(room.room) and x+modX >= 0 and
    x+modX < len(room.room[y+modY]) and room.room[y+modY][x+modX] == chr

#If there is an empty place to the left
proc leftEmpty(room:Room, x, y:int): bool = checkChar(room, x, y, '.', modX= -1)

#If there is a door to the left 
proc leftDoor(room:Room, x, y:int): bool = checkChar(room, x, y, 'D', modX= -1)

#Check if the spot above the given coordenates is empty
proc upEmpty(room:Room, x, y:int): bool = checkChar(room, x, y, '.', modY= -1)

#Check if there is a door above this spot
proc upDoor(room:Room, x, y:int): bool = checkChar(room, x, y, 'D', modY= -1)

#Check if there is a door above this point
proc upStair(room:Room, x, y:int): bool = checkChar(room, x, y, '^', modY= -1)

#Check if the spot the right is empty
proc rightEmpty(room:Room, x, y:int): bool = 
    x < len(room.room[0]) and room.room[y][x] == '.'

#Check if there is a door to the right
proc rightDoor(room:Room, x, y:int): bool = checkChar(room, x, y, 'D', modX=1)

#Check if the spot below the coordinates is empty space
proc downEmpty(room:Room, x, y:int): bool = checkChar(room, x, y, '.', modY=1)

#Check if there is a door below the coordinates given
proc downDoor(room:Room, x, y:int): bool = checkChar(room, x, y, 'D', modY=1)

#Deals with whatever action is associated with a keypress in the game
proc handleKeypress*(key:char, player:var Player, floor:var Floor, done, draw:var bool, level:var int) =
    #Get the current room to be looked at
    let room = Room (floor.floor[player.roomY][player.roomX])

    stdout.setCursorPos(30,1)
    stdout.write("LAST KEY: " & key)
    stdout.setCursorPos(41, 1)
    stdout.write("-> " & $player.xpos & " " & $(len(room.room[0])-1))

    #If this is movement for player
    if key in "wasd":
        #Moving up, check if theres a door, or empty space
        if key == 'w':
            #If there is an empty space, move up
            if upEmpty(room, player.xpos, player.ypos):
                #Move the player on screen up one space
                floor.moveChar(player, '@', player.xpos, player.ypos, player.xpos, player.ypos-1, color=fgCyan)
                player.ypos -= 1 #Make the player move up one space
            
            #IF there is a door above, enter new room
            #[elif upDoor(room, player.xpos, player.ypos):
                draw = true #Tell program to draw new room
                player.roomY -= 1 #Move up one room
                #Move player into new room
                floor.enterRoom(player, player.roomX, player.roomY+1, 3)
            
            #If there is a staircase above, go to next floor
            elif upStair(room, player.xpos, player.ypos):
                inc level #Go to next level
                draw = true #Say we need to draw new room
                floor = newFloor() #Make a new floor
                floor.spawnPlayer(player) #Spawn player in  new room
            ]#
        
        #If moving left check if there is a door or open space
        elif key == 'a':
            #If there is an open space, move there
            if leftEmpty(room, player.xpos, player.ypos):
                #Move player on screen left one space
                floor.moveChar(player, '@', player.xpos, player.ypos, player.xpos-1, player.ypos, color=fgCyan)
                player.xpos -= 1 #Save change in x position
            
            #If there is a door to the left, move to the next room
            #[elif leftDoor(room, player.xpos, player.ypos):
                draw = true #Say we will draw the room
                player.roomX -= 1 #Move to room to the left
                #Move into the corresponding room
                floor.enterRoom(player, player.roomX+1, player.roomY, 2)
            ]#
        
        #Move right, check if there is a door or empty space
        elif key == 'd':

            #If there is an empty space, move there
            if checkChar(room, player.xpos, player.ypos, '.', modX=1): #rightEmpty(room, player.xpos, player.ypos):
                stdout.write("rght")

                #Move player right one space
                floor.moveChar(player, '@', player.xpos, player.ypos, player.xpos+1, player.ypos, fgCyan)
                player.xpos += 1 #Save change in x
            
            #If there is a door to the right, enter room
            #[elif rightDoor(room, player.xpos, player.ypos):
                draw = true #Draw in the next room
                #Move us to the room to the right
                player.roomX += 1
                #Enter from the left
                floor.enterRoom(player, player.roomX-1, player.roomY, 4)
            ]#

        #Move down, check for door or empty space
        elif key == 's':
            #If there is empty spot, move down
            if downEmpty(room, player.xpos, player.ypos):
                #Show movement
                floor.moveChar(player, '@', player.xpos, player.ypos, player.xpos, player.ypos+1, fgCyan)
                player.ypos += 1 #Save change in y
            
            #Enter the new room from the north
            #[elif downDoor(room, player.xpos, player.ypos):
                draw = true #Draw the next room in
                player.roomY += 1 #Move down one room
                #Enter the room
                floor.enterRoom(player, player.roomX, player.roomY-1, 1)
            ]#
        
    #The player opening up a map
    elif key == 'm':
        stdout.setCursorPos(0,0) #Set position to 0,0
        colorWrite("Explored", fgWhite)
        stdout.write " - "

        drawMap(floor) #Draw out the map for the user

        var chr = '\00' #Temp. var
        #Wait until player enters esc character
        while chr != '\x1b': chr = getch()

