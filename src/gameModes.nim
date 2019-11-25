#[
This will have each function which corresponds to every
game mode in the game. Hopefully, this will include a
'story mode', as well as a 'infinite mode' which is more
of an acarde-esc game mode.
Author: Alastar Slater
Date: 9/28/2019
]#
import floorsAndIO, playerAndObjs, terminal, movement

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
        player: Player = newPlayer(0, 0)  #The player object for this game
        #The first floor the player is on
        floor: Floor = newFloor()
        dialog: seq[string] #All text relating to stuff that happened
        level = 1 #What floor the player is on
        draw  = true #If the room needs to be drawn
        done  = false #If the player is done or not
    
    #Spawns the player in a random room (true - is story mode)
    floor.spawnPlayer(player, level, true)

    #The current room the player is in
    var room  = Room floor.floor[player.roomY][player.roomX] 

    player.health = 100
    player.potions = 1
    
    while not done:
        stdout.setCursorPos(0,0) #Center cursor
        stdout.eraseLine() #Erase line at 0,0
        #Floor level, health of player, and number of potions
        stdout.write("Level: " & $level & " | Hp: " & $(player.health) & " | Potions: " & $player.potions)

        #stdout.write("FX: ", player.roomX, " FY: ", player.roomY)
        #stdout.write(" FXLEN: ", len(floor.floor[0]), " FYLEN: ", len(floor.floor)-1)

        #If we are told to draw the room, do so
        if draw == true:
            stdout.eraseScreen() #Clear the screen
            drawRoom(room)       #Draw in the room
            dialog.writeDialog() #Write out dialog
            draw = false
            continue
        
        dialog.writeDialog() #Write in dialog
        let chr = getch()    #Get character input from user
        dialog.clearDialog() #Clear out dialog on screen
        dialog = @[]         #Clear out dialog list

        #If player presses escape, exit
        if chr == '\x1b': break

        #Handles the player's keypresses                     (This is story mode)
        chr.handleKeypress(dialog, player, floor, done, draw, level, story=true)
        #Get the new room
        room = Room floor.floor[player.roomY][player.roomX]
    
        