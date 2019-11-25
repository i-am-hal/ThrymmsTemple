#[
Defines the parent monster class,
and has each individual monster that could
be in the game.
Author: Alastar Slater
Date: 10/27/2019
]#

import random, math, sequtils

type
    #The basic root monster in the game
    Monster* = ref object of RootObj
        pos*: (int, int)   #Position of this monster in the room
        chr*: char         #Character to represent this monster
        speed*: int        #How many turns of player it takes to move
        speedRefresh*: int #Refresh the speed
        health*:int        #How much hp they have overall
        dmg*: int          #How damadge this monster deals
        chance*:int        #1/chance chance of hitting anything
    
    #Creates a mimic, which when 'awakened' will start moving
    Mimic* = ref object of Monster
        awake*: bool

#Creates a new blank monster
func newMonster*(pos:(int,int), chr: char, speed, health, dmg, chance: int): Monster =
    #Creates a new monster object
    Monster(pos:pos, chr:chr, speed:speed, speedRefresh:speed, health:health, dmg:dmg, chance:chance)

#===[   SIMPLER MONSTERS   ]===#

#Creates a new zombie, simple monster
func newZombie*(pos:(int,int)): Monster = newMonster(pos, 'Z', speed=2, health=11, dmg=5, chance=3)

#Create a new ker, simple monster, 50% of hitting target
func newKer*(pos:(int,int)): Monster = newMonster(pos, 'K', speed=0, health=6, dmg=2, chance=2)

#Create a new nymph, %25 of hitting target
func newNymph*(pos:(int,int)): Monster = newMonster(pos, 'N', speed=0, health=6, dmg=3, chance=4)

#Creates a mimic, not as simple, 50% accuracy
func newMimic*(pos:(int,int)): Mimic = Mimic(pos:pos, chr:'#', speed:1, speedRefresh:1, health:10, dmg:7, chance:2, awake:false)

#===[   MOVEMENT   ]===#

#All the target locations of a regular monster
proc defaultTargetLocations(mob:Monster, pos:(int, int)): seq[(int, int)] =
    #Positions left of, right of, above, and below of player
    @[(pos[0]-1, pos[1]), (pos[0]+1, pos[1]), (pos[0], pos[1]-1), (pos[0], pos[1]+1)]

#Get locations just out of reach of the player
proc warlockTargetLocations(pos:(int, int)): seq[(int, int)] =
    return @[(pos[0]-2, pos[1]), (pos[0]-1, pos[1]-1), (pos[0]-1, pos[1]+1),
        (pos[0]+1, pos[1]-1), (pos[0]+1, pos[1]+1), (pos[0]+2, pos[1]),
        (pos[0], pos[1]-2), (pos[0], pos[1]+2)]

#Gets target locations of any kind of monster
proc getTargetLocations*(mob:Monster, pos:(int, int)): seq[(int, int)] =
    #Return positions to check if player is in them
    if mob of Mimic and not (Mimic mob).awake:
        return warlockTargetLocations(pos)
    
    else: #if just monster, use default locations
        return mob.defaultTargetLocations(pos)

#===[   SPAWNER   ]===#

#Returns the max monster id for spawning monsters on this floor
proc getMonsterDiversity(floor:int): int =
    result = 3 #Start at diversity 3 (Kers, Zombies, Nymphs)

    #Between levels 5 - 8, include warlocks
    if 5 <= floor and floor <= 8:
        result = 4
    
    #Between levels 9 - 12, include warlocks, specters
    elif 9 <= floor and floor <= 12:
        result = 5
    
    #Between levels 13 - 16, include warlocks, specters, behemoths
    elif 13 <= floor and floor <= 16:
        result = 6

#Spawns corresponding monster from positino and id
proc getMonsterFromId(id: int, pos:(int, int)): Monster =
    #[
        1/ELSE - Zombie
        2 - Ker
        3 - Nymph
    ]#
    #Returns corresponding monster
    case id:
        of 2: newKer(pos) #Id 2 is Ker
        of 3: newNymph(pos) #Id 3 is Nymph
        else: newZombie(pos) #Otherwise, zombie

#Given a position and floor level, spawn monster
proc spawnMob*(floor:var int, pos:(int, int)): Monster =
    let
        #Get the max mob id for this floor
        maxMonsterId = getMonsterDiversity(floor)
        #Pick which kind of monster to generate
        monsterId = rand(1.. maxMonsterId)
    
    #Get monster to spawn from it's id and gives position
    getMonsterFromId(monsterId, pos)

#Spawns a random monster
proc randomMobSpawn*(pos:(int, int)): Monster =
    let id = rand(1.. 3) #Get id of the monster to spawn 
    #Spawns corresponding monster with it's id
    getMonsterFromId(id, pos)


#===[   MOVEMENT   ]===#

#Gets the component vector between the start and end
func componentVector(start:(int, int), final:(int, int)): (int, int) =
    (final[0] - start[0], final[1] - start[1])

#Gives raw distance between two points
proc distanceToPoint(start:(int, int), final:(int, int)): int =
    #Get the component vector that goes from start -> end
    let vector = componentVector(start, final)

    #Return the distance without evaluating the square root
    return vector[0] ^ 2 + vector[1] ^ 2

#Returns point that has shortest distance
proc smallestDist(start:(int, int), targets:seq[(int, int)]): (int, int) =
    result = targets[0]                       #Start with the first 
    var dist = distanceToPoint(start, result) #Starting distance

    #Go through the rest of the points to test
    for i in 1.. targets.high():
        let
            endPoint = targets[i]  #Point to test
            endPointDist = distanceToPoint(start, endPoint) #Distance from start -> endPoint
        
        #If new point has shorter distance, save it
        if dist > endPointDist:
            dist = endPointDist #Save new end point's distance
            result = endPoint   #Save new end point

#Preserved signs for moving up/down, left/right however
# have each one have length of one
func unitVector(vector:(int, int)): (int, int) =
    func isNeg(x:int): bool = x < 0     #If the number is negative
    func isPos(x:int): bool = isNeg(-x) #If the number is positive

    #[ X ORDINATE ]#

    if isNeg(vector[0]): #If is neg, x = -1
        result[0] = -1
    
    elif isPos(vector[0]): #If pos, x = 1
        result[0] = 1
    
    else: #Otherwise, x = 0
        result[0] = 0
    
    #[ Y ORDINATE ]#

    if isNeg(vector[1]): #if neg, y = -1
        result[1] = -1
    
    elif isPos(vector[1]): #If pos, y = 1
        result[1] = 1
    
    else: #Otherwise, y = 0
        result[1] = 0

#Get all of the positions that aren't being used
proc removeUsedSpaces(allMobs:seq[Monster], positions:seq[(int, int)]): seq[(int, int)] =
    for position in positions:
        var posUsed = false #If this position is used
        #Go through each monster to check position
        for mob in allMobs:
            #If this position is used, mark it as so
            if mob.pos == position:
                posUsed = true
        
        #Add the position if it is not used
        if not posUsed:
            result.add position 
            
#Get the unit vector used for moving the monster to it's next position to attack
proc getMoveVector*(allMobs:seq[Monster], start:(int, int), targets:seq[(int, int)]): (int, int) =
    let 
        removeSelf = allMobs.filter(proc(x:Monster):bool = x.pos != start) #Removes mob that is this monster we are looking at
        openSpaces = removeUsedSpaces(removeSelf, targets)                 #Get the spaces not used by other monsters
    
    #Return vector saying not to move, if no spaces are open
    if len(openSpaces) == 0:
        return (0, 0)
    
    let
        targetPos = smallestDist(start, openSpaces)                        #Get the path with the shortest distance
        pathVector = componentVector(start, targetPos)                     #Get the vector moving to this end position
    result = unitVector(pathVector)                                        #Calculates the unit vector used for moving monster
        
#Return true if one of the ordinates is 0
func simpleVec*(vector:(int, int)): bool =
    #If one of the ordinates is 0, it is a simple vector
    if vector[0] == 0 and vector[1] != 0 or vector[0] != 0 and vector[1] == 0:
        return true
    return false

