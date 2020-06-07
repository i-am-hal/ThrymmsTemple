#[
    This is a file that holds all of the tooling used
    for debugging during runetime (allows to spawn
    specific monsters, set player health, kill all
    monsters in a room, etc.)
    Author: Alastar Slater
    Date: 6/5/2020
]#
import monsters, playerAndObjs, terminal, floorsAndIO, tables
from strutils import splitWhiteSpace, toLowerAscii, isDigit, parseInt
from sequtils import map, all

let
    #List of all the debug commands
    DEBUG_COMMANDS = @["exit", "help", "health", "spawn", "clear", "floor"]
    #For each command, gives an explanation for how it words
    DEBUG_COMMAND_INFO = {
        "exit":"Closes the debug terminal.",
        "help":"Gives info on a given command (if one given) otherwise lists commands.",
        "health":"Allows you to override the health of the player and set it to something.",
        "clear":"Removes all monsters from the room.",
        "spawn":"Spawns a monster in the room (if no monster given, lists monsters available).",
        "floor":"Given an number, makes that the current floor number (valid floors for story 1-17)."
    }.toTable

    #All monsters that are supported for the command SPAWN
    SUPPORTED_MONSTERS = @["zombie", "ker", "nymph", "mimic", "warlock", "specter"]
    #Gives the ID numbers for each monster
    MONSTER_IDS = {
        "zombie":1, "ker":2, "nymph":3, "warlock":4, "specter":5
    }.toTable

#Tests whether or not this string is an integer
proc isInt(str:string):bool =
    #Empty string, it is false
    if len(str) == 0: return false

    result = true
    for chr in str:
        result = result and chr.isDigit()

#Checks whether or not the given space is a free space
func openSpace(floor:var Floor, player:var Player, xpos: int, ypos: int): bool =
    (Room floor.floor[player.roomY][player.roomX]).room[ypos][xpos] == '.'

#Main entrypoint for the debug terminal
proc debugTerminal*(player:var Player, floor:var Floor, floorLevel:var int) = 
    stdout.eraseScreen()
    stdout.setCursorPos(0,0)
    echo "Debug Console (type Help for info, Exit to stop)\n"

    var done = false

    while not done:
        stdout.write("> ")
        #Gets input and saves it as a list of words
        let input = stdin.readLine().toLowerAscii().splitWhiteSpace()

        #Get input again if there is nothing
        if len(input) == 0:
            continue

        #If enters exit, close
        elif input[0] in @["exit", "quit"] or input[0] == "\x1b":
            done = true
        
        #If they want help, see how to help
        elif input[0] == "help":
            #If no command given, or command not known one, lists all commands
            if len(input) == 1:
                echo "Here's a list of all known commands:"
                #Print out name of each command
                for command in DEBUG_COMMANDS: echo "- " & command
                stdout.write("\n")
            
            #Otherwise, known command, give definition
            elif input[1] in DEBUG_COMMANDS:
                echo DEBUG_COMMAND_INFO[input[1]] & "\n"
            
            #Otherwise, not recognized command
            else:
                echo input[1] & " is not a known command."
        
        #Allows user to override the health of the player
        elif input[0] == "health":
            #If only the command or there isn't an integer supplied, complain
            if len(input) == 1 or not isInt(input[1]):
                echo "You must supply an integer to set the health to.\n"
            
            #Override the health of the player to this supplied number
            elif isInt(input[1]):
                player.health = parseInt(input[1])
                echo "Success.\n"
        
        #Allows user to spawn monsters in the room
        elif input[0] == "spawn":
            #If no monster is given, then give all monsters available
            if len(input) == 1:
                echo "Here are all of the monsters you can spawn:"

                #List out all the monsters
                for monster in SUPPORTED_MONSTERS:
                    echo "- " & monster
                
                stdout.write('\n')
            
            #Complain that this isn't a supported monster
            elif not (input[1] in SUPPORTED_MONSTERS):
                echo "That is not a supported monster.\n"
            
            #If a mimic, say that we can't spawn mimics
            elif input[1] == "mimic":
                echo "Sorry, we can't spawn mimics on demand.\n"
            
            #Otherwise, get the id of the monster, and spawn it
            else:
                var successful = false #If the operation was successful or not

                let 
                    monsterId = MONSTER_IDS[input[1]] #Get id for this monster
                    roomWidth = (Room floor.floor[player.roomY][player.roomX]).width-2
                    roomHeight = (Room floor.floor[player.roomY][player.roomX]).height-3

                #Check if 1,1 is an open space
                if openSpace(floor, player, 1, 1):
                    let mob = getMonsterFromId(monsterId, (1,1))
                    #Draw the monster into the map
                    floor.moveChar(player, mob.chr, mob.pos[0], mob.pos[1], mob.pos[0], mob.pos[1], showChange=false)
                    #Add it to the list of monsters
                    (Room floor.floor[player.roomY][player.roomX]).mobs.add mob
                    successful = true #Mark this was a successful operation
                
                #Check if 1,h is open
                elif openSpace(floor, player, 1, roomHeight):
                    let mob = getMonsterFromId(monsterId, (1, roomHeight))
                    #Draw the monster into the map
                    floor.moveChar(player, mob.chr, mob.pos[0], mob.pos[1], mob.pos[0], mob.pos[1], showChange=false)
                    #Add it to the list of monsters
                    (Room floor.floor[player.roomY][player.roomX]).mobs.add mob
                    successful = true #Mark this was a successful operation
                
                #Check if w,1 is open
                elif openSpace(floor, player, roomWidth, 1):
                    let mob = getMonsterFromId(monsterId, (roomWidth, 1))
                    #Draw the monster into the map
                    floor.moveChar(player, mob.chr, mob.pos[0], mob.pos[1], mob.pos[0], mob.pos[1], showChange=false)
                    #Add it to the list of monsters
                    (Room floor.floor[player.roomY][player.roomX]).mobs.add mob
                    successful = true #Mark this was a successful operation
                
                #Check if w,h is open
                elif openSpace(floor, player, roomWidth, roomHeight):
                    let mob = getMonsterFromId(monsterId, (roomWidth, roomHeight))
                    #Draw the monster into the map
                    floor.moveChar(player, mob.chr, mob.pos[0], mob.pos[1], mob.pos[0], mob.pos[1], showChange=false)
                    #Add it to the list of monsters
                    (Room floor.floor[player.roomY][player.roomX]).mobs.add mob
                    successful = true #Mark this was a successful operation

                #Say if this was successful
                if successful: 
                    echo "Success.\n"
                else: #Otherwise, not successful
                    echo "No room in four corners to spawn monster."
        
        #Clear out all monsters from the room
        elif input[0] == "clear":
            var room = Room floor.floor[player.roomY][player.roomX]
            #Remove the characters from the room
            for mob in room.mobs:
                floor.moveChar(player, '.', mob.pos[0], mob.pos[1], mob.pos[0], mob.pos[1], showChange=false)
            #Clear out mobs list
            room.mobs = @[]
            echo "Success.\n"
        
        #Try to set the floor number to a given number by user
        elif input[0] == "floor":
            #If this is a valid integer value, change the floor level
            if isInt(input[1]):
                floorLevel = parseInt(input[1])
                echo "Success.\n"
            
            #Complain that the user didn't use an integer for floor number
            else:
                echo "You must supply an integer for the floor level.\n"

        #Otherwise say not a known command
        else:
            echo input[0] & " is not a recognized command.\n"

    discard 0