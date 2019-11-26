#[
This has the player object for the game.
Has basic info like health, position, inventory,
and weapon and weapon.
Author: Alastar Slater
Date: 9/28/2019
]#

import random, terminal, strformat, strutils

#randomize()

#Max number of items in bag
let MAX_BAG_LENGTH = 6

#The player object to be used in the game
type
    #Parent node to all game objects
    GameObject* = ref object of RootObj

    #An in game object that occupies space in the room
    PointObject* = ref object of GameObject
        pos*: (int, int) #The point in the room

    #A chest in the game
    Chest* = ref object of PointObject 
        number*: int   #Says this is the Nth chest in room
        potions*: int  #Number of potions in the chest
        gold*: int     #Amount of gold in the chest 
        #The armor and weapons in this chest
        armor*, weapon*: GameItem 

    #A base game object that can be collected in inventories
    GameItem* = ref object of GameObject
        name*, desc*: string
    
    #An item that degrades over time
    Armor* = ref object of GameItem 
        #full health, and amount this degrades by
        health*, degrade*: float 
    
    #A weapon object
    Weapon* = ref object of Armor
        dmg*: float #Damadge dealt 
        chance*: int #%chance of hitting (1/chance)
        melee*: bool #If this is or is not a melee weapon
    
    #Tthe base player object
    Player* = object
        health*: int  #The amount of health th eplayer has
        dmg*: int     #Default damadge dealt by user without weapon
        xpos*, ypos*: int #The x and y coordinates of the player
        roomX*, roomY*: int #Room player is in (x,y coordinates for room)
        weapon*: GameItem #Equipped weapon
        armor*: GameItem #Equipped armor
        #Inventory holds a series of game objects
        inventory*: seq[GameItem]
        #Number of health potions
        potions*: int
        #Number of gold coins
        gold*: int

#Creates a new piece of armor, need to know name, description, amount it degrades by 
proc newArmor*(name="", desc="", degrade: float): Armor =
    Armor(name:name, desc:desc, degrade:degrade, health:100.0)

#Create a new weapon, must know name, desc, degrade, damadge dealth + chance
proc newWeapon*[T:int | float64](name="", desc="", degrade, dmg:T, chance:int, melee=true): Weapon =
    Weapon(name:name, desc:desc, health:100.0, dmg:float(dmg),
        chance:chance, degrade:float(degrade), melee:melee)

#Creates a new player object for the game
proc newPlayer*(x, y: int): Player =
    Player(health: 15, dmg:5, xpos: x, ypos: y, weapon:GameItem(name:"None", desc:""), armor:GameItem(name:"None", desc:""))

#=[     ITEM DECLARATIONS     ]=#

#Picks a piece of armor
proc pickArmor*: GameItem =
    #Choose a piece of armor
    let choice = rand(8)

    #Select corresponding piece of armor
    case choice:
        of 1: #Return Mystic armor
            return newArmor("Mystic Armor", degrade=1.1,
            desc="""
            The Mystics were a group that once followed under Thrymm's teachings.
            They had mastered the art of arcane magic. After gaining much power from their arts,
            they rejected Thrymm's teachings saying that Thrymm was a lie. Their armor and weapons
            are the only things left of them.
            """)
        
        of 2: #Return Dragon Scale
            return newArmor("Dragon Scale", degrade=2,
            desc="""
            It is believed in the old world, that dragons ruled over the human race and slaughtered the humans
            for fun. Blasphemers will tell you that there were never such a thing as dragons in the old world.
            Thrymm tells us that we musn't listen to the Blasphemers.
            """)
        
        of 3: #Return Old Leather
            return newArmor("Old Leather", degrade=2.5,
            desc="""
            Arcane texts tell us that leather was a commodity in many different areas in the old world.
            Alas, not much survived the Great Inferno, nor the Endless Winter. Anything left is terribly
            old, most crumbles away. Seems you found a more intact sample.
            """)
        
        of 4: #Armor of the weak
            return newArmor("Armor of the Weak", degrade=5,
            desc="""
            Worn by previous travelers that thought they could climb the tower and gain riches.
            Needless to say, they all died- they were weak anyhow. None of them knew of Thrymm's
            teachings.
            """)
        
        of 5: #1 hit wonder
            return newArmor("One Hit Wonder", degrade=100,
            desc="""
            Made as joke by the Mystics, upon one strike of the armor, it will be destroyed.
            Sadly, Jason wasn't told of this joke and died shortly after going into battle
            with this armor on. Still got a good laugh, from both sides.
            """)
        
        of 6: #Cardboard
            return newArmor("Cardboard", degrade=33.333333,
            desc="""
            After a child used some cardboard to build a mighty fort, he stated it
            ".. made of the strongest material on earth!" After salvaging the cardboard,
            Thrymm's followers then created as much armor as they could. From attacks from
            both the Mystics and from Gerald's followers. So, they needed every possible
            advantage.
            """)
        
        of 7: #Thrymm's flesh (second best, 100 hits)
            return newArmor("Thrymm's Flesh", degrade=1,
            desc="""
            This is some of the supposed flesh of Thrymm. He had- before leaving this world
            behind, shed his skin, and gave it as a gift to his followers. It gave them extended
            life, but wore down their minds.
            """)
        
        else: #Returns NOTHING
            return GameItem(name:"None", desc:"")

#Randomly picks a weapon
proc pickWeapon*: GameItem =
    #Pick a piece of weapon
    let choice = rand(10)

    #Choose which weapon to return
    case choice:
        of 1: #Return an excaliber instance
            return GameItem newWeapon("Excalibur", degrade=2, dmg=15, chance=2,
            desc="""
            Once wielded by and old world king, it was sadly left behind. Thrymm (in his great wisdom)
            told his followers to craft copies of the holy weapon, as a symbol that they remembered the
            old world. Each copy of this sword was personally blessed by Thrymm himself.
            """)
        
        of 2: #Return Joseph's bow
            return GameItem newWeapon("Joseph's Bow", degrade=1, dmg=12, chance=2, melee=false,
            desc="""
            One of Thrymm's followers, he was a great archer, having put many an enemy of
            Thrymm into the grave on many occasions. This must be one of his numerous bows.
            Before his death, he was trying to master shooting two bows at once.
            """)
        
        of 3: #Return Harold's axe
            return GameItem newWeapon("Harold's Axe", degrade=1.1, dmg=12, chance=3,
            desc="""
            Harold was one of Thrymm's first followers. He was weak. He was, however, brash and
            loyal. These being attractive attributes in a follower of Thrymm. Harold failed his
            mission when trying to kill a group of blasphemers. This is one of his axes, unused
            for years.
            """)
        
        of 4: #Return William's gun
            return GameItem newWeapon("William's Gun", degrade=1.6, dmg=10, chance=3, melee=false,
            desc="""
            William resisted Thrymm's teachings ruling on guns. He loved the old world technology.
            He felt so powerful with them that he defied Thrymm. His brother, Harold, was sent
            to pursue and show William the consequences of defying Thrymm. This is one of William's
            many guns.
            """)
        
        of 5: #Return Elizabeth's Dagger
            return GameItem newWeapon("Elizabeth's Dagger", degrade=4, dmg=10, chance=2,
            desc="""
            Elizabeth was His first love. Before he started the Great Inferno he asked Thrymm
            if Elizabeth could be saved. Thrymm told him that she could, and aided in keeping
            her safe. Alas, the Endless Winter ate away at her. Using a dagger she took her life.
            Thrymm later told him to keep the dagger. Perhaps you found this dagger?     
            """)
        
        of 6, 7: #Return Excalilame
            #Most of this weapon's stats are random
            return GameItem newWeapon("Excalilame", degrade=rand(2..50), dmg=rand(1..12), chance=rand(2..4),
            desc="""
            This is sadly, one of many copies of Excaliber that weren't blessed by Thrymm.
            Because of this, the quality of each blade significantly varies betweem each
            one.
            """)
        
        of 8, 9: #Return Noble Bow
            return GameItem newWeapon("Noble Bow", degrade=5, dmg=5, chance=3, melee=false,
            desc="""
            A bow of a nobleman- most likely one that sought fame. Alas, they didn't make it.
            It should suit you just fine though, don't you think?
            """)
        
        of 10: #Return Toothpick
            return GameItem newWeapon("Toothpick", dmg=0.1, degrade=30, chance=2,
            desc="""
            One of the many weapons used by those who followed Gerald. Gerald was once
            a follower of Thrymm, but (and no one really knows what caused it) he began
            to lose his hold on reality. He began spewing propoganda, saying that Thrymm
            was spreading lies. He also thought that
            """)
        
        else: #Otherwise return nothing
            return GameItem(name:"None", desc:"")

#Generates a number of potions
proc genPotions*: int =
    let val = rand(0.. 10)

    #Figure out how many potions to give
    case val:
        of 5, 6:   result = 1
        of 7, 8:   result = 2
        of 9, 10:  result = 3
        #Anything not covered is 0 postions
        else:      result = 0

#Generates number of gold in chest
proc genGold*: int =
    #[
        1 - 7: 0 gold 
        8 - 10: 5 gold
        11 - 13: 10 gold
        14 - 17: 15 gold
        18 - 20: 20 gold
    ]#
    let val = rand(1.. 25)

    #Figure out amount of gold to give
    case val:
        #Any of these, zero gold coins
        of 1, 2, 3, 4, 5, 6, 7: result = 0
        #Return 5 gold
        of 8, 9, 10: result = 5
        #Return 10 gold
        of 11, 12, 13: result = 10
        #Return 15 gold
        of 14, 15, 16, 17: result = 15
        #Return 20 gold
        of 18, 19, 20: result = 20
        #Any larger number, use it as number of coins
        else: result = val

#Creates a new chest instance
proc newChest*(position:(int, int), number:int): Chest =
    #Create a new chest object for the game
    Chest(number:number, pos:position, potions:genPotions(), gold:genGold(), weapon:pickWeapon(), armor:pickArmor())

#===[   FUNCTIONS FOR UI   ]===#

#prints text for a game item
proc sayItemText[T:Armor | Weapon | GameItem](x:T, prefix:string, secPrefix="| ", shPostfix="") =
    #If this is a weapon, print out text for it
    if x of Weapon:
        #Give the name of the weapon
        echo prefix & fmt"{x.name}" & shPostfix #(Add on second header prefix) 
        #The type of weapon this is
        var weaponType = "Ranged"

        #If this is a melee weapon, make it say so
        if (Weapon x).melee:
            weaponType = "Melee"

        #Give info on weapon
        echo secPrefix & fmt"(Uses: {itemUses(Armor x)}, Dmg: {int((Weapon x).dmg)}, Type: {weaponType}, Accuracy: 1/{(Weapon x).chance})"
    
    #Generate the text relating to this piece of armor
    elif x of Armor:
        #Print the prefix then the info 
        echo prefix & fmt"{x.name} (Uses: {itemUses(Armor x)})" & shPostFix  
    
    #Generate the text for none
    else:
        echo prefix & "None"

#===[   CHEST USER INTERFACE   ]===#

#Write dialog text to screen
proc writeDialog(dialog:seq[string], column=45) =
    var line = 1 #Starting line

    for text in dialog:
        stdout.setCursorPos(column, line) #Setup line position
        stdout.write(text)            #Write out text
        inc(line)                     #Move to next line

#Return integer uses of the armor/weapon
proc itemUses*[A:Armor | Weapon](item: A): int = int(100 / item.degrade)

#Draws the UI of the chest
proc drawChestUI(self:var Chest) =
    #[
         _______________________________
        | CHEST                         |
        |=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=|
        | ESC: Exit                     |
        | F: take potions  E: take gold |
        | R: take weapon  C: take armor |
        |              ~~~              |
        | Gold: <GOLD>                  |
        | Potions: <POTIONS>            |
        | Armor: <ARMOR NAME>           |
        |   (Uses:<USES>)               |
        | Weapon: <WEAPON NAME>         |
        |   (Mod:<MOD>, Uses:<USES>)    |
         -------------------------------
    ]#
    echo " ___________________________________________________"
    echo fmt"| CHEST {self.number} |"
    echo "|========="
    echo "| ESC: Exit                     "
    echo "| F: take potions  E: take gold "
    echo "| R: equip weapon  C: equip armor "
    echo "| V: bag weapon/armor"
    echo "|              ~~~              "
    echo fmt"| Gold: {self.gold}"                                              #Show number of gold coins
    echo fmt"| Potions: {self.potions}"                                        #Show number of health potions

    #[ SHOW STATS OF ARMOR ]#
    sayItemText(self.armor, "| Armor: ")

    #[ SHOW STATS OF WEAPON ]#
    sayItemText(self.weapon, "| Weapon: ", "| ")

    echo " ---------------------------------------------------"

#This is the top level ui of the chest
proc openChest*(self:var Chest, player:var Player) =
    var
        done = false              #If done with this menu or not
        chr = '\0'                #The character input
        dialog: seq[string] = @[] #All the dialog relating to actions

    #Keep going until the player wants to stop
    while not done:
        #Clear out the screen to draw it again
        stdout.eraseScreen()
        stdout.setCursorPos(0,0)

        #If the player presses escape, exit out
        if chr == '\x1b':
            break
        
        #Taking the gold
        elif chr == 'e':
            player.gold += self.gold           #Give the gold to the player
            dialog.add fmt"+{self.gold} gold!" #Tell player amount of gold gained
            self.gold = 0                      #Remove all gold from chest
        
        #Take the potions
        elif chr == 'f':
            player.potions += self.potions                  #Give the player all of the potions
            dialog.add fmt"+{self.potions} health potions!" #Tell player amount of potions gained
            self.potions = 0                                #Remove all potions from chest
        
        #equip the weapon
        elif chr == 'r':
            let weapon = player.weapon  #Weapon of player
            player.weapon = self.weapon #Give chest's weapon to player
            self.weapon = weapon        #Put player's armor in chest
        
        #Equip the armor
        elif chr == 'c':
            let armor = player.armor  #Armor of player
            player.armor = self.armor #Give chests armor to player
            self.armor = armor        #Give player's armor to chest
        
        #Bag weapon / armor
        elif chr == 'v':
            self.drawChestUI() #Let user see weapon and armor before
            #Give extra prompt to player as to what they want to bag
            echo   " ----------------------------------------- "
            echo   "| Do you want to bag the armor or weapon? |"
            echo   "|                                         |"
            echo   "| (A)rmor        (W)eapon        (C)ancel |"
            echo   " ----------------------------------------- "

            #Continue getting input until choice is made
            while not (chr.toLowerAscii() in @['a', 'w', 'c']):
                chr = getch().toLowerAscii()
            
            #Try to add armor to bag, and it IS armor, but also if there is room in the bag
            if chr == 'a' and self.armor of Armor and len(player.inventory) <= MAX_BAG_LENGTH:
                player.inventory.add(self.armor)            #Stow away this armor into inventory
                self.armor = GameItem(name:"None", desc:"") #Clear out armor in chest
            
            #Try to add weapon to bag, and it IS a weapon, but also if there is room in the bag
            elif chr == 'w' and self.weapon of Weapon and len(player.inventory) <= MAX_BAG_LENGTH:
                player.inventory.add(self.weapon)            #Put weapon into player's inventory
                self.weapon = GameItem(name:"None", desc:"") #Clear out weapon in chest
            
            #Tell user they cannot add anything to bag
            elif len(player.inventory) > MAX_BAG_LENGTH:
                dialog.add "Your bag is too full!"
            
            #If player trying to bag nothing, say so
            elif chr == 'a' and not (self.armor of Armor) or chr == 'w' and not (self.weapon of Weapon):
                dialog.add "There is nothing to put in your bag!"
            
            #At end, clear out screen
            stdout.eraseScreen()
            stdout.setCursorPos(0,0)

        #Draw the ui so the user can see any changes
        self.drawChestUI()
        dialog.writeDialog(column=54) #Write all dialog to screen

        chr = getch().toLowerAscii() #Get character input (in lowercase)
        dialog = @[] #Empty dialog

#===[   INVENTORY USER INTERFACE   ]===#

#Writes out the description for the player to read
proc readItemDesc(x:GameItem) =
    stdout.eraseScreen()     #Erase screen, reset cursor
    stdout.setCursorPos(0,0)

    echo "DESCRIPTION:"
    echo "=============="

    #split up the text by whitespace
    let text = x.desc.splitWhitespace()

    var
        wordLimit = 11
        words = 1
    
    #Go through each word in the text
    for word in text:
        stdout.write(word & ' ') #Print out word

        #If this is multiple of 15, print new line
        if words mod wordLimit == 0:
            stdout.write('\n')

        inc(words) #Increment the number of words
    
    #Prompt before user exits
    echo "\n\n(Press anything to exit.)"
    discard getch()
    
#Draw the user interface for the player
proc drawBagUI(self:var Player, select:var int) =
    stdout.eraseScreen()     #Erase last screen image
    stdout.setCursorPos(0,0) #Reset cursor position for drawing

    echo " ___________________________________________________"
    echo "| INVENTORY ] BAG"
    echo "|==================================================="
    echo "| Esc: Exit menu  W/S: Up/Down through selection"
    echo "| R: Read item description  Enter: Equip item"
    echo "| D: Destroy selected item"
    echo "|"

    let selectIndex = select - 1 #Index of the selected item

    #Go through the selection of every item
    for i in 0..len(self.inventory)-1:
        let item = self.inventory[i] #Get the item from bag

        #If this is the selected item, change second header postfix
        if selectIndex == i:
            item.sayItemText(fmt"| {i+1}: ", "|  ", shPostfix=" (*)")
        
        else: #If this item not selected, have unselected item
            item.sayItemText(fmt"| {i+1}: ", "|  ", shPostfix=" ()")

    echo " ---------------------------------------------------"

#The bag of the user, used for managing items
proc playerBag(self:var Player) =
    var
        chr = '\0'    #The character the user gave as input
        selection = 1 #The selection made by user

    #Keep this menu open until the player wants to stop
    while true:
        self.drawBagUI(selection)    #Draw the user interface for the user
        chr = getch().toLowerAscii() #get next character input, save as lowercase character
        
        #If user is done with menu, close out of it
        if chr == '\x1b':
            break
        
        #If the user wants to equip this item
        elif chr == '\r':
            let item = self.inventory[selection - 1] #Get item from inventory
            self.inventory.delete(selection - 1)     #Remove item from inventory

            #If selection > 1, decrease by one
            if selection > 1: selection -= 1

            #If the item is a weapon, equip it as a weapon
            if item of Weapon:
                let equippedWeapon = self.weapon #Save equipped weapon for now
                self.weapon = item               #Give the weapon to the player

                #If this is actually a weapon, add it to bag
                if item of Weapon and equippedWeapon.name != "None":
                    self.inventory.add equippedWeapon
            
            #If this item is armor, equip it
            elif item of Armor:
                let equippedArmor = self.armor #Save equipped armor for now
                self.armor = item              #Give the armor to the player

                #If this is actually armor, add it to the bag
                if item of Armor and equippedArmor.name != "None":
                    self.inventory.add equippedArmor
        
        #if the player wants to read the description of the selected item
        elif chr == 'r' and len(self.inventory) > 0:
            #Read the selected item's description
            readItemDesc(self.inventory[selection - 1])
        
        #If user goes up, decrease selection by one
        elif chr == 'w' and selection > 1:
            selection -= 1
        
        #If user goes down, increase selection by one
        elif chr == 's' and selection < len(self.inventory):
            selection += 1
        
        #If user deletes current item
        elif chr == 'd' and len(self.inventory) > 0:
            #Ddecrease selection by one
            if selection > 1:
                selection -= 1
            
            #Remove this item from the inventory
            self.inventory.delete(selection-1)

#Draw in the interface for the inventory
proc drawInventoryUI(self:var Player) =
    #[
     _____________
    | INVENTORY
    |============
    | Esc: Exit menu
    | B: Open bag
    |
    | Gold:
    | Health:
    | <WEAPON TEXT>
    | <ARMOR TEXT>
     ------------------
    ]#
    #Clear screen and set cursor positions
    stdout.eraseScreen()
    stdout.setCursorPos(0, 0)

    echo " ___________________________________________________"
    echo "| INVENTORY"
    echo "|==================================================="
    echo "| Esc: Exit menu"
    echo "| B: Open bag  R: Move weapon to bag"
    echo "| C: Move armor to bag"
    echo "|"
    echo fmt"| Gold: {self.gold}"
    echo fmt"| Health: {self.health}"
    echo fmt"| Potions: {self.potions}"

    #[ SHOW STATS OF ARMOR ]#
    sayItemText(self.armor, "| Armor: ")

    #[ SHOW STATS OF WEAPON ]#
    sayItemText(self.weapon, "| Weapon: ", "| ")

    echo " ---------------------------------------------------"

#The player inventory
proc playerInventory*(self:var Player) =
    var
        chr = '\0'          #Character input from the user
        dialog: seq[string] #All of the dialog

    #Continue menu until the user is done
    while true:
        self.drawInventoryUI()        #Draw the UI for the player
        dialog.writeDialog(column=54) #Write out all dialog
        chr = getch().toLowerAscii()  #Get input from the user as a single character
        dialog = @[]                  #Clear out dialog list

        #If player presses escape, exit menu
        if chr == '\x1b':
            break
        
        #If the player wants to look into the bag, open it
        elif chr == 'b':
            self.playerBag()
        
        #If the player wants to move weapon to bag
        elif chr == 'r' and len(self.inventory) < MAX_BAG_LENGTH:
            self.inventory.add self.weapon               #Add the weapon to bag
            self.weapon = GameItem(name:"None", desc:"") #Give player none as weapon
        
        #If the player wants to move armor to bag, and has space
        elif chr == 'c' and len(self.inventory) < MAX_BAG_LENGTH:
            self.inventory.add self.armor               #Add armor to bag
            self.armor = GameItem(name:"None", desc:"") #Gibe player no armor
        
        #Tell user that their bag is full
        elif chr in @['c', 'r'] and len(self.inventory) == MAX_BAG_LENGTH:
            dialog.add "Your bag is full!"
        

