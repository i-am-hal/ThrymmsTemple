#[
This file contains everything from Input & Output as well
as everything relating to rooms and floors and their corresponding
methods and functions.
Author: Alastar Slater
Date: 9/30/2019
]#

import math, terminal, random, sequtils, strutils, playerAndObjs, monsters


#===[          FLOORS & ROOMS          ]===#

type
    RoomObj* = ref object of RootObj

    #All an unloaded room needs to know is how many exits it has, and where
    UnloadedRoom* = ref object of RoomObj
        roomType*: int
    
    #This has all the relevent info for a regular room
    Room* = ref object of RoomObj
        #The dimensions of the room are integers
        height*, width*: int
        #The ascii version of the room itself
        room*: seq[seq[char]]
        #All of the game obejcts in this room
        objs*: seq[PointObject]
        #All of the monsters in this room
        mobs*: seq[Monster]
    
    #A floor is a series of rooms 
    Floor* = object
        #Dimensions of this floor (total rooms = height * width)
        height, width: int
        #Raw representation of the room
        floor*: seq[seq[RoomObj]]
        #Number of rooms not yet generated
        nonGenRooms*: int
        #If we have stairs or not
        hasStairs*: bool
        #If the first room has been generated
        genFirstRoom: bool

#[    FLOOR & ROOM METHODS    ]# 

#Calculates maximum number of chests of a room of height x width
func numberOfChests(height, width:int): int =
    let minimum = min(height, width)
    #Return integer number of chests
    int(ceil(minimum/2 - minimum/3))

#Creates the ascii version of a w * h room
proc mkAsciiRoom(width, height: int): seq[seq[char]] =
    for h in 1..height+1:
        #The column being made
        var column: seq[char] = @[]

        #If this is the first row
        if h == 1 or h == height+1:
            column.add ' '
            #Add w '-' between caps
            for w in 1..width:
                column.add '-'
            column.add ' '
        
        #If this isn't the last row
        elif h <= height:
            column.add '|'
            #Add empty spaces between walls
            for w in 1..width:
                column.add '.'
            column.add '|'

        #Add the column
        result.add column
            
#Makes the needed table of unloaded rooms for a new floor
proc mkFloorList(width, height: int): seq[seq[RoomObj]] =
    for h in 1..height:
        #The current row being made
        var row: seq[RoomObj]

        #Creates the first row in the rooms
        if h == 1:
            row.add UnloadedRoom(roomType: 1) #left cap
            #Add in the rooms inbetween 1 & 2
            for w in 1..width:
                row.add UnloadedRoom(roomType: 2) 
            row.add UnloadedRoom(roomType: 3) #Right cap
        
        #If middle rows between 1st and last
        elif h < height:
            row.add UnloadedRoom(roomType: 4) #left cap
            #Add in a bunch of middle 5 rooms
            for w in 1..width:
                row.add UnloadedRoom(roomType: 5)
            row.add UnloadedRoom(roomType: 6) #right cap
        
        #last row
        else:
            row.add UnloadedRoom(roomType: 7) #Left cap
            #Ad a bunch of 8s in the middle
            for w in 1..width:
                row.add UnloadedRoom(roomType: 8)

            row.add UnloadedRoom(roomType: 9) #right cap
        
        result.add row #Add on the row

#Returns a list of all possible positions in the room
proc getAllPos(w, h: int): seq[(int, int)] =
    #Add every possuble x, y coordinate
    for y in 1..h-1:
        for x in 1..w:
            result.add (x, y)

#Randomly picks a position
proc getPos(positions:var seq[(int,int)]): (int, int) =
    var retPos = sample(positions)
    #Remove the used position
    positions = positions.filter(proc(pos:(int,int)): bool = pos != retPos)
    #Return the given position
    retPos

#Returns a new room instance
proc newRoom(floor:var Floor, w, h, roomType: int, level:var int, storyMode:bool): Room =
    #[Room types: [NORTH, EAST, SOUTH, WEST]
        0

        1 2 3
        4 5 6
        7 8 9
    ]#

    let 
        #Check if has monsters in this room (60% of rooms have monsters)
        hasMonsters = rand(1.. 5) >= 3
        #Max number of chests in this room
        numChests = numberOfChests(h, w)

        #Figure out what exits this room has
        exits =
            case roomType:
                of 1: [false, true, true, false]   #E, S
                of 2: [false, true, true, true]    #E, S, W
                of 3: [false, false, true, true]   #S, W
                of 4: [true, true, true, false]    #N, E, S
                of 5: [true, true, true, true]     #N, E, S, W
                of 6: [true, false, true, true]    #N, S, W
                of 7: [true, true, false, false]   #N, E
                of 8: [true, true, false, true]    #N, E, W
                of 9: [true, false, false, true]   #N, W
                else: [false, false, false, false] #No exits
    
    var
        #Make ascii version of room
        room = mkAsciiRoom(w, h)
        #Get all of the possible positions
        allpos = getAllPos(len(room[0])-2, len(room)-2)
    
    if exits[0]: #If exit due north
        let
            y = 1                     #First real cell
            x = int(len(room[0]) / 2) #Middlemost x
        
        room[y-1][x] = 'D' #Draw in the door

        #Removes spots around the door
        allpos = allpos.filter(proc(pos:(int,int)):bool =
            not (pos in @[(x+1,y), (x-1,y), (x,y)]))

    if exits[1]: #if exit due east
        let
            y = int(len(room) / 2) #Middle row
            x = len(room[0]) - 2 #First column
        
        room[y][x+1] = 'D' #Draw in the door

        #Filter out areas around the door
        allpos = allpos.filter(proc(pos:(int,int)):bool =
            not (pos in @[(x,y+1),(x,y),(x,y-1)]))
    
    if exits[2]: #if exit due south
        let
            y = len(room)-2           #last real row 
            x = int(len(room[0]) / 2) #Middlemost x
        
        room[y+1][x] = 'D' #Draw in the door

        #Removes spots around the door
        allpos = allpos.filter(proc(pos:(int,int)):bool =
            not (pos in @[(x+1,y), (x-1,y), (x,y)]))
    
    if exits[3]: #If exit due west
        let
            y = int(len(room) / 2) #Middle row
            x = 1 #First column
        
        room[y][x-1] = 'D' #Draw in the door

        #Filter out areas around the door
        allpos = allpos.filter(proc(pos:(int,int)):bool =
            not (pos in @[(x,y+1),(x,y),(x,y-1)]))
    
    #If not first room, and no stairs, try to gen stairs
    if floor.genFirstRoom and not floor.hasStairs and rand(1.. floor.nonGenRooms) == 1:
        let #Get x & y coords of stairs
            y = int(len(room) / 2)
            x = int(len(room[0]) / 2)
        #Draw in the staircase since we got it
        room[y][x] = '^'
        #Note that we have stairs now
        floor.hasStairs = true
        #Remove positions around stairs (left + right of stairs)
        allpos =  allpos.filter(proc(pos:(int,int)):bool =
            not (pos in @[(x,y), (x-1, y), (x+1, y)]))

    var
        objs: seq[PointObject] = @[] #All of the game objects in this room (chests, any petunias)
        mobs: seq[Monster] = @[]     #All of the monsters in the room
        chestNum = 1                 #Number of chest

    #Go and try to generate each chest in the room
    for _ in 1.. numChests:
        #Stop the loop as soon as there aren't enough positions
        if len(allpos) == 0: break

        let
            #Flip coin as to generate chest 
            genChest = rand(0.. 1)
            isMimic = rand(1.. 5) #40% of being mimic
        
        #If we are generating a chest, do so
        if genChest == 1 and isMimic > 2:              #[or not hasMonsters:]# 
            #Creates the chest object to add
            let chest = newChest(allpos.getPos(), chestNum)
            objs.add(PointObject chest) #Add the chest to list of objects in room
            room[chest.pos[1]][chest.pos[0]] = '#' #Draw in chest
            inc(chestNum) #Increment the number of chest this is
    
        #If we are spawning a mimic into the room (can spawn in any room)
        elif genChest == 1 and isMimic <= 2:           #[and hasMonsters]#
            let mimic = newMimic(allpos.getPos()) #Create the mimic for this room
            mobs.add(Monster mimic) #Add the mimic to the list of monsters
            room[mimic.pos[1]][mimic.pos[0]] = '#'
    
    #If this room has monsters in it 
    if hasMonsters:
        let maxMonsters = rand(0.. 4) #At max, 4 monsters

        #Generate each monster in the room
        for _ in 1.. maxMonsters:
            #Stop making monsters if there are no more positions
            if len(allpos) == 0: break

            #Spawn monsters based on what floor it is
            if storyMode == true:
                #Create the monster to add to the room
                let monster = spawnMob(level, allpos.getPos())
                mobs.add monster #Add the monster to list of monsters
                #Draw in the monster to this room
                room[monster.pos[1]][monster.pos[0]] = monster.chr
            
            #If not story mode, spawn any monster
            elif not storyMode:
                #Randomly picks and spawns a monster
                let monster = randomMobSpawn(allpos.getPos())
                #Draw in the monster into the room
                room[monster.pos[1]][monster.pos[0]] = monster.chr

    #Return the new room instance
    Room(height:h+2, width:w+2, room:room, objs:objs, mobs:mobs)
        
#Loads in a room that doesn't yet exist
proc loadRoom(self:var Floor, x, y: int, level:var int, story:bool) =
    #Load in the room if not loaded in
    if self.floor[y][x] of UnloadedRoom:
        let
            #Get the type of room from the unloaded room
            roomType = (UnloadedRoom self.floor[y][x]).roomType
            width    = rand(4..15) #Generate width + height of room
            height   = rand(3..15)
        #Generate the room
        self.floor[y][x] = self.newRoom(width, height, roomType, level, story)
        self.nonGenRooms -= 1 #Decrease number of non generated rooms

#Sets up room, player for a new room
proc spawnPlayer*(self:var Floor, player:var Player, level:var int, story:bool) =
    let #Pick a random index for a random room
        roomX = rand(0..(self.width-1))
        roomY = rand(0..(self.height-1))
    
    self.loadRoom(roomX, roomY, level, story) #Loads in the room

    let 
        #The room just generated
        room = Room self.floor[roomY][roomX]
        #Gen. center of room for the player
        y = int(len(room.room) / 2)
        x = int(len(room.room[0]) / 2)
    
    #Draw the player into the room
    (Room self.floor[roomY][roomX]).room[y][x] = '@'
    
    #Update the player to the center of the new room
    player.xpos = x
    player.ypos = y

    #update which room the player is in
    player.roomX = roomX
    player.roomY = roomY

    #Mark that we made the first room
    self.genFirstRoom = true

#Forward declare so nim doesn't complain
proc moveChar*(chr:char, startX, startY, endX, endY:int, color=fgWhite)

#Moves some character on screen to a different location
proc moveChar*(self:var Floor, player:var Player, chr:char, startX, startY, endX, endY:int, color=fgWhite) =
    #Removes last place on screen
    (Room self.floor[player.roomY][player.roomX]).room[startY][startX] = '.'
    #Draw in character to new place
    (Room self.floor[player.roomY][player.roomX]).room[endY][endX] = chr

    #Moves the character on screen
    chr.moveChar(startX, startY+1, endX, endY+1, color)

#Moves player into a new room so they have 'continuity'
#exitFrom: 1-north, 2-east, 3-south, 4-west, else-center
proc enterRoom*(self:var Floor, player:var Player, roomX, roomY, exitFrom:int, level:var int, story:bool) =
    #Remove character from last position
    (Room self.floor[roomY][roomX]).room[player.ypos][player.xpos] = '.'

    #Load in the room we are now entering
    self.loadRoom(player.roomX, player.roomY, level, story)

    #Use this room for figuring positions
    let room = (Room self.floor[player.roomY][player.roomX])

    case exitFrom:
        of 1: #Appear at top of room
            let #Get the x and y coordinates
                y = 1
                x = int(len(room.room[y]) / 2)
            #Save x,y pos.
            player.xpos = x 
            player.ypos = y
        of 3: #Appear at bottom of screen
            let #Get the x and y coordinates
                y = len(room.room) - 2
                x = int(len(room.room[y]) / 2)
            #Save x,y pos.
            player.xpos = x 
            player.ypos = y
        of 2: #Appear right
            let #Get x,y coordinates
                y = int(len(room.room) / 2)
                x = len(room.room[y]) - 2
            #Save positions
            player.xpos = x
            player.ypos = y
        of 4: #Appear left 
            let #Get x,y coordinates
                y = int(len(room.room) / 2)
                x = 1
            #Save positions
            player.xpos = x
            player.ypos = y
        else: #Otherwise, spawn in middle
            let #Get x,y for middle
                y = int(len(room.room) / 2)
                x = int(len(room.room[y]) / 2)
            #Save positions
            player.xpos = x
            player.ypos = y
    
    #Draw in this character into the new room
    (Room self.floor[player.roomY][player.roomX]).room[player.ypos][player.xpos] = '@'

#Generates a new floor to use
proc newFloor*: Floor =
    let #Generate width + height
        height = rand(2..11)
        width  = rand(2..11)

    Floor(height:height, width:width, nonGenRooms:height*width,
        floor:mkFloorList(width, height))

#===[          IO          ]===#

#Given some text and color, writes text in that color
template colorWrite*[T: string | char](text:T, color:ForegroundColor) =
    #Set the color for the text to be written
    stdout.setForegroundColor(color)
    stdout.write(text) #Write the text
    stdout.setForegroundColor(fgWhite) #Set back to white

#Changes a character in the room's position
proc moveChar*(chr:char, startX, startY, endX, endY: int, color=fgWhite) =
    stdout.setCursorPos(startX, startY) #Move to 1st pos
    stdout.write '.' #Write in replacement empty
    stdout.setCursorPos(endX, endY) #Move to 2nd pos
    colorWrite(chr, color) #write in the character

#Draws in the room for the game, colors text
proc drawRoom*(room: Room) =
    #Get in position to draw the room
    stdout.setCursorPos(0, 1)
    #Go through and draw each character
    for row in room.room:
        for chr in row:
            #Draw in the character as cyan
            if chr == '@':
                colorWrite('@', fgCyan)
            
            #If a monster, color red
            elif chr in "ZKNmW":
                colorWrite(chr, fgRed)
            
            else: #Otherwise, just write in character
                stdout.write chr
        #End the row
        stdout.write '\n'

#writes text in a color or style
proc csWrite*[T: string | char](text:T, color=fgWhite, style: set[Style]={styleBright}) =
    stdout.setForegroundColor(color) #Set color of foreground
    writeStyled(text, style) #Writes text in this style

#Checks if this char is in the room
proc roomHasChar(room: Room, chr:char): bool =
    #If we have this character return true
    for row in room.room:
        for rmChr in row:
            if rmChr == chr:
                return true
    false #Otherwise return false

#Draw in the map for convience to the user
proc drawMap*(floor: FLoor) =
    stdout.setCursorPos(0, 2) #Set cursor to draw the map
    for row in floor.floor:
        #Go through every object in this row for displaying
        for roomObj in row:
            #Write out the room as not explored
            if roomObj of UnloadedRoom:
                stdout.write ' ' 
            
            #If this room has the exit, color it yellow
            elif roomObj of Room and roomHasChar(Room roomObj, '^'):
                colorWrite('#', fgGreen)
            
            #Make the current room blink
            elif roomObj of Room and roomHasChar(Room roomObj, '@'):
                colorWrite("#", fgCyan)
            
            else: #Unimportant room
                stdout.write('#')
            
        stdout.write '\n' #End line

#Write out a list of text to the screen
proc writeDialog*(dialog:seq[string], column=45) =
    var line = 1 #Start at line 1

    for text in dialog:
        stdout.setCursorPos(column, line) #Set cursor to this line
        stdout.write(text)            #Write line of text
        inc(line)                     #Move to next line

#Gets max number in the array of numbers
proc max[T: int | float](arr:openarray[T]): T =
    #Return first element if has length of one
    if len(arr) == 1:
        result = arr[0]

    #If there is enough values to test
    elif len(arr) >= 2:
        result = arr[0] #Get first number as max

        for index in 1 .. arr.high:
            let num = arr[index] #Get number at this index

            #We found next maximum, save it
            if result < num:
                result = num 

#Clear out written dialog on screen
proc clearDialog*(dialog:seq[string]) =
    let
        #Get the length of each dialog piece
        textLengths = dialog.map proc(x:string):int = len(x)
        #Longest length of text
        maxLength = max(textLengths)
    
    var line = 1 #Start at line 1
    
    for _ in dialog:
        stdout.setCursorPos(45, line)       #Set cursor to this line
        stdout.write(' '.repeat(maxLength)) #Clear out text on this line w/ spaces
        inc(line)                           #Move to next line

