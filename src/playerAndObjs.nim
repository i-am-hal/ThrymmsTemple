#[
This has the player object for the game.
Has basic info like health, position, inventory,
and weapon and weapon.
Author: Alastar Slater
Date: 9/28/2019
]#

#The player object to be used in the game
type
    #A base game object that can be collected in inventories
    GameObj* = ref object of RootObj
        name*, desc*: string
    
    #An item that degrades over time
    Armor* = ref object of GameObj
        #full health, and amount this degrades by
        health*, degrade*: int
    
    #A weapon object
    Weapon* = ref object of Armor
        #Damadge death, %chance of hitting (1/chance)
        dmg*, chance: int
    
    #Tthe base player object
    Player* = object
        health*: int  #The amount of health th eplayer has
        xpos*, ypos*: int #The x and y coordinates of the player
        roomX*, roomY*: int #Room player is in (x,y coordinates for room)
        #Inventory holds a series of game objects
        inventory*: seq[GameObj]
        #Number of health potions
        potions*: int

#Creates a new piece of armor, need to know name, description, amount it degrades by 
proc newArmor*(name="", desc="", degrade: int): Armor =
    Armor(name:name, desc:desc, degrade:degrade, health:100)

#Create a new weapon, must know name, desc, degrade, damadge dealth + chance
proc newWeapon*(name="", desc="", degrade, dmg, chance:int): Weapon =
    Weapon(name:name, desc:desc, health:100, dmg:dmg, chance:chance)

#Creates a new player object for the game
proc newPlayer*(x, y: int): Player =
    Player(health: 15, xpos: x, ypos: y)
