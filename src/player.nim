#[
This has the player object for the game.
Has basic info like health, position, inventory,
and weapon and weapon.
Author: Alastar Slater
Date: 9/28/2019
]#

#The player object to be used in the game
type Player* = object
    health*: int  #The amount of health th eplayer has
    xpos*, ypos*: int #The x and y coordinates of the player
    roomX*, roomY*: int #Room player is in (x,y coordinates for room)

#Creates a new player object for the game
proc newPlayer*(x, y: int): Player =
    Player(health: 15, xpos: x, ypos: y)