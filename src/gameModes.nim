#[
This will have each function which corresponds to every
game mode in the game. Hopefully, this will include a
'story mode', as well as a 'infinite mode' which is more
of an acarde-esc game mode.
Author: Alastar Slater
Date: 9/28/2019
]#
import floorsAndIO, playerAndObjs, terminal, movement, strutils

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



#Tells the player that they died
proc playerDied =
    stdout.eraseScreen()
    centerText("You Died.", fgRed, true)

#This is used to ask if player really wants to quit session
proc quitGame: bool =
    let 
        size = terminalSize()        #Size of the terminal window
        quitText = "(Y)es / (N)o"    #Text for what key to press to quit
    stdout.eraseScreen()             #Erase the entire screen
    var chr: char                    #Keypress of the player

    centerText("Quit the Game?") #Bring up prompt
    
    #Set cursor position for the quitText
    stdout.setCursorPos(int(size[0]/2) - int(len(quitText)/2), int(size[1]/2)+1)
    stdout.write(quitText) #Print out the quit text

    #Keep getting key presses until its Y or N
    while chr != 'y' and chr != 'n': chr = getch() 

    #If yes, stop, we should quit
    if chr == 'y': return true
    #Otherwise, return false, don't stop
    else: return false

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

    var 
        #The current room the player is in
        room  = Room floor.floor[player.roomY][player.roomX] 
        #The size of the terminal window
        windowSize = terminalSize()

    #Give player 2 potions at the start
    player.potions = 2
    
    while not done:
        stdout.setCursorPos(0,0) #Center cursor
        stdout.eraseLine() #Erase line at 0,0

        #[ CHECK IF PLAYER DIED ]#

        #Check if player is dead, if so, say they died :(((
        if player.health <= 0:
            done = true  #Mark that player is dead
            playerDied() #Tell the player that they died
            break        #Exit out of game loop

        #[ GAME LOOP ]#

        #Floor level, health of player, and number of potions
        stdout.write("Level: " & $level & " | Hp: " & $(player.health) & " | Potions: " & $player.potions)

        #Get the current size of the terminal, to check if there were changes
        let new_window_size = terminalSize()

        #If we are told to draw the room, do so
        if draw == true or windowSize != new_window_size:
            #If window size changed, update, hide cursor
            if windowSize != new_window_size:
                windowSize = terminalSize() #Update size of window
                stdout.hideCursor()         #Hide the cursor from user
            stdout.eraseScreen()        #Clear the screen
            drawRoom(room)              #Draw in the room
            dialog.writeDialog()        #Write out dialog
            draw = false
            continue
        
        dialog.writeDialog(room.width + 4) #Write in dialog
        let chr = getch()                  #Get character input from user
        dialog.clearDialog(room.width + 4) #Clear out dialog on screen
        dialog = @[]                       #Clear out dialog list

        #If player presses escape, see if they want to stop
        if chr == '\x1b':
            done = quitGame()
            draw = true
            continue

        #Handles the player's keypresses                     (This is story mode)
        chr.handleKeypress(dialog, player, floor, done, draw, level, story=true)
        #Get the new room
        room = Room floor.floor[player.roomY][player.roomX]
    
        