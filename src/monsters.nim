#[
Defines the parent monster class,
and has each individual monster that could
be in the game.
Author: Alastar Slater
Date: 10/27/2019
]#

import random

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


