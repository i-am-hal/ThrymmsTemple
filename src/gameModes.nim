#[
This will have each function which corresponds to every
game mode in the game. Hopefully, this will include a
'story mode', as well as a 'infinite mode' which is more
of an acarde-esc game mode.
Author: Alastar Slater
Date: 9/28/2019
]#
import floorsAndIO, player, terminal, movement

#[
NUMBER OF CHESTS:

               / min(h,w)    min(h,w) \
f(h,w) =  ciel(  ________  - ________  )
               \     2           3    /

Gives the number of chests for a room,
where h = height of room, w = width of room
and where h and w >= 3

Examples:
    f(3,3) = 1
]#


#This is the story mode for the game
#Player goes from floor 1 -> 18, to then fight Malachi
proc storyMode* =
    var
        player: Player  #The player object for this game
        #The first floor the player is on
        floor: Floor = newFloor()
    
    #Spawns the player in a random room
    floor.spawnPlayer(player)

    var
        #The current room the player is in
        room  = Room floor.floor[player.roomY][player.roomX] 
        level = 1 #What floor the player is on
        draw  = true #If the room needs to be drawn
        done  = false #If the player is done or not
    
    while not done:
        stdout.setCursorPos(0,0) #Center cursor
        stdout.eraseLine() #Erase line at 0,0
        #Location in room & on screen
        #stdout.write("LEVEL: " & $level)

        #If we are told to draw the room, do so
        if draw == true:
            stdout.eraseScreen() #Clear the screen
            drawRoom(room)  #Draw in the room
            draw = false
            continue
        
        let chr = getch() #get character input from user

        #If player presses escape, exit
        if chr == '\x1b': break

        #Set cursor at end of room
        stdout.setCursorPos(0, len(room.room) + 1)
        stdout.write chr

        #Handles the player's keypresses
        chr.handleKeypress(player, floor, done, draw, level)
    
        