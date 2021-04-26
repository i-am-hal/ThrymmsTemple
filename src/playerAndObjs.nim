#[
This has the player object for the game.
Has basic info like health, position, inventory,
and weapon and weapon.
Author: Alastar Slater
Date: 9/28/2019
]#
import random, terminal, strformat, #[strutils,]# sequtils
from strutils import toLowerAscii, splitWhiteSpace
from math import sum

#(define some constants for this file)
let 
    #Max number of items in bag
    MAX_BAG_LENGTH = 6
    #Max number of topics to ask Petunia about
    MAX_TOPIC_NUMBER = 3

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
    
    #A shop in the game
    Shop* = ref object of PointObject
        potions*: int                      #The number of potions the shop (Petunia) has to sell
        potionCost*: int                   #The cost (in gold) per potion
        hasTalked*: bool                   #Whether or not the player talked to Petunia before
        talkTopics*: seq[(string, string)] #All of the topics this instance can talk about
        armor*, weapon*: GameItem          #The weapon and armor piece that is on sale
        armorCost*, weaponCost*: int       #The cost for buying the armor and weapon respectively

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
            was spreading lies. He also thought that if you used a toothpick as a weapon
            it would purify your soul.
            """)
        
        else: #Otherwise return nothing
            return GameItem(name:"None", desc:"")

#Given a weapon, it will use the stats of the weapon to generate a cost in gold.
proc getWeaponCost*(weapon:Weapon): int =
    let
        degrade = weapon.degrade
        chance = weapon.chance
        dmg = weapon.dmg
    
    #Calculate base price for a piece of weponry.
    # num-of-potential-hits x damage-per-success
    int((10 / degrade) * (dmg / float(chance)))

#Given armor, return cost of armor in gold
proc getArmorCost*(armor:Armor): int = 
    let degrade = armor.degrade
    #Calculate cost by getting number of hits before the armor
    # breaks, multiply by two so the highest armor costs ~50 gold
    int(100 / (2 * degrade))

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
        #Any larger number, use it as number of coins (but half it)
        else: result = int(val/2)

#Creates a new chest instance
proc newChest*(position:(int, int), number:int): Chest =
    #Create a new chest object for the game
    Chest(number:number, pos:position, potions:genPotions(), gold:genGold(), weapon:pickWeapon(), armor:pickArmor())

#Forward declare this so we can use it in making shop func
proc makeTopicList: seq[(string, string)]

#Creates a new shop instance
proc newShop*(position:(int, int)): Shop =
    let #Get the weapon and armor to be sold
        weapon = pickWeapon()
        armor = pickArmor()
    
    var #Default prices (because item could be nothing)
        weaponPrice = 0
        armorPrice = 0
    
    #IF this weapon isn't nothing, calculate it's actual price
    if weapon of Weapon:
        weaponPrice = getWeaponCost(Weapon weapon)
    
    #If this armor is not nothing, calculate the price
    if armor of Armor:
        armorPrice = getArmorCost(Armor armor)

    #Return the shop object, complete with a weapon/armor to hopefully sell and prices for those things.
    Shop(pos:position, potions:genPotions(), potionCost:rand(7..50), weapon:weapon, armor:armor, 
    armorCost:armorPrice, weaponCost:weaponPrice, talkTopics:makeTopicList())

#===[   CONVIENCE FUNCTIONS   ]===#

#Return true if the given item is Nothing
proc isNoneObj(item: GameItem): bool = item == GameItem(name:"None", desc:"")

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
        echo prefix & "None" & shPostfix

#Used to print out a sort of pop-up menu (like for making some choices in some other menu)
# Takes x-pos for all text, and starting y-pos for text, and then all the lines to print
proc popupMenu(xpos, startYpos:int, text:openarray[string]) =
    var yPos = startYpos

    for line in text:
        stdout.setCursorPos(xpos, yPos)
        echo line
        yPos += 1

#===[   CHEST USER INTERFACE   ]===#

#Write dialog text to screen
proc writeDialog(dialog:seq[string], column=45) =
    var line = 1 #Starting line

    for text in dialog:
        stdout.setCursorPos(column, line) #Setup line position
        stdout.write(text)            #Write out text
        inc(line)                     #Move to next line

#Return integer uses of the armor/weapon
proc itemUses*[A:Armor | Weapon](item: A): int = int(item.health / item.degrade)

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
        
        #Taking the gold, and there IS GOLD TO TAKE
        elif chr == 'e' and self.gold > 0:
            player.gold += self.gold           #Give the gold to the player
            dialog.add fmt"+{self.gold} gold!" #Tell player amount of gold gained
            self.gold = 0                      #Remove all gold from chest
        
        #Take the potions, and there are potions to take
        elif chr == 'f' and self.potions > 0:
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
            #stdout.setCursorPos(5, 3)
            #Lines for the prompt that will be printed out
            let lines = [
                " _________________________________________ ",
                "| Do you want to bag the armor or weapon? |",
                "|                                         |",
                "| (A)rmor        (W)eapon        (C)ancel |",
                " ----------------------------------------- "
            ]
            
            #Make the sub menu for choosing between what to pick
            popupMenu(5, 5, lines)

            #Continue getting input until choice is made
            while not (chr.toLowerAscii() in @['a', 'w', 'c', '\x1b']):
                chr = getch().toLowerAscii()
            
            #Try to add armor to bag, and it IS armor, but also if there is room in the bag
            if chr == 'a' and self.armor of Armor and len(player.inventory) < MAX_BAG_LENGTH:
                player.inventory.add(self.armor)            #Stow away this armor into inventory
                self.armor = GameItem(name:"None", desc:"") #Clear out armor in chest
            
            #Try to add weapon to bag, and it IS a weapon, but also if there is room in the bag
            elif chr == 'w' and self.weapon of Weapon and len(player.inventory) < MAX_BAG_LENGTH:
                player.inventory.add(self.weapon)            #Put weapon into player's inventory
                self.weapon = GameItem(name:"None", desc:"") #Clear out weapon in chest
            
            #Tell user they cannot add anything to bag
            elif len(player.inventory) >= MAX_BAG_LENGTH:
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

#Prints text out to screen, makes it so a certain number of words
# are allowed per line (supposed to wrap text around)
proc wrapEcho(text:string, wordsPerLine=11, linePrefix="") =
    #Split this text into single words
    let text = text.splitWhitespace()
    #Number of words on this line
    var words = 1
    #Go through each word in the text
    for word in text:
        stdout.write(word & ' ') #Print out word

        #If this is multiple of 15, print new line
        if words mod wordsPerLine == 0:
            stdout.write("\n" & linePrefix)

        inc(words) #Increment the number of words

#Writes out the description for the player to read
proc readItemDesc(x:GameItem) =
    stdout.eraseScreen()     #Erase screen, reset cursor
    stdout.setCursorPos(0,0)

    echo "DESCRIPTION:"
    echo "=============="

    #Print out the description of the item
    wrapEcho(x.desc)
    
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

    #Only go through and list all items in bag if there are things in the bag
    if len(self.inventory) > 0:
        #Go through the selection of every item
        for i in 0..len(self.inventory)-1:
            let item = self.inventory[i] #Get the item from bag

            #If this is the selected item, change second header postfix
            if selectIndex == i:
                item.sayItemText(fmt"| {i+1}: ", "|  ", shPostfix=" (*)")
            
            else: #If this item not selected, have unselected item
                item.sayItemText(fmt"| {i+1}: ", "|  ", shPostfix=" ()")
    
    else: #Otherwise, say nothing in the bag
        echo "| Nothing is in your bag."

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
        
#===[   SHOP USER INTERFACE   ]===#

#Gets a single topic to talk to petunia about
proc getTalkTopic: (string, string) =
    #A list of all the topics you can talk about
    let topics = @[
        #Response to how she is in so many places
        ("Sightings",
        "You ask her how you manage to run into her so often. She says: \"A woman never reveals her secrests. Now, do you want to buy something sweetie?\""),
        #Another response to how she shows up so often
        ("Sightings",
        "You ask how she seems to be in so many places in this tower. She says: \"I just go where I'm needed. Is that good enough for you sweetie?\""),
        #Last response to being asked to how she is all over the place
        ("Sightings",
        "You ask how she seems to show up often. She says: \"Hun', I feel like that's the least of your worries.\""),
        #Question about Petunia personally, mainly why she's here
        ("Herself",
        "You ask why she is here, selling things to stangers. She responds: \"Well, it's a great way of meeting people! I get to talk to some very interesting people you know. Somtimes.\""),
        #Question about Petunia personally, mainly why is she is all the way out here
        ("Herself",
        "You ask why she's way out here. She says: \"Well hun', I'm on a journey to find the snake of my dreams. Not like you'd understand.\""),
        #Questin to why she isn't in a rainforrest
        ("Herself",
        "You ask why she isn't in a rainforrest or something. She responds: \"Well sweetie, I can't go home if there is no home for me to go to.\""),
        #Ask Petunia why she's wearing a party hat
        ("Party hat",
        "You ask her why she's wearing a party hat. She says: \"Well girls just wanna have fun.\""),
        #Ask Petunia about dragons
        ("Dragons",
        "You decide to ask her about dragons. Her eyes light up and she says: \"Oh sweetie, you don't even know, my mother was a dragon you see.\""),
        #Ask petunia about dragons
        ("Dragons",
        "You ask Petunia about dragons. She responds: \"I don't think you'll see a full dragon anytime soon hun'. You don't quite make the cut for a 'classical adventurer', sorry sweetie.\""),
        #Ask about the god thrymm (Hasn't met the god, and doesn't really want to)
        ("Thrymm",
        "You ask about the god Thrymm. She looks uncertain and says: \"I've never met him. But honey, I don't think I would want to- from what I've gathered from his 'religion'.\""),
        #Ask about 'him' (the first prophet of thrymm)
        ("Thrymm's first prophet",
        "You ask about 'him'. Petunia then says: \"You mean that 'him' guy from that cult? All I know is from what Thrymm's followers have said. He sounds like an old grumpy muffin to me.\""),
        #Users asks about her opinion about thrymm's teachings
        ("Thrymm's teachings",
        "You ask for her opinion of Thrymm's teachings. Petunia says: \"Oh sweetie, you don't believe what he says, do you? Because honestly he sounds very.. 'not fun'. Also hes a creep!\""),
        #Get Petunia's opinion on gerald
        ("Gerald",
        "You ask about Gerald. She says (after thinking for a few moments): \"Oh that Gerald! Well, not to get too political hun', but I like him. Yeah- he seems a bit.. unhinged, but I like some of the things he says.\""),
        #Ask about the following of gerald
        ("Gerald's following",
        "You decide to inquire about Gerald's following. She responds with: \"Well hun', they're sort of anti-Thrymm movement? They have some interesting ideas on that cult too. Don't know why they use toothpicks though.\""),
        #Ask about this tower
        ("This tower",
        "You ask about this tower you're in. She slowly responds with: \"I really don't know.. sorry sweetie. From what I can tell, has some significance to Thrymm's cult thingie. Nice atmosphere though!\""),
        #ask for what she does know about the mystics
        ("The mystics",
        "You ask her about the Mystics. She says: \"Sorry sweetie, I don't really know much about them. But they seem- at least to me, like pranksters with more resources.\"")
    ]

    #Return one of the topics
    sample(topics)

#Makes the list of topics to talk about for Petunia
proc makeTopicList: seq[(string, string)] = 
    #Set of subject matter
    var topic_titles: seq[string]
    
    #While we don't have enough topics (<= MAX_TOPIC_NUMBER)
    while len(result) <= MAX_TOPIC_NUMBER:
        let topic = getTalkTopic()

        #If no topics yet, just add this topic
        if len(result) == 0:
            result.add(topic)
            topic_titles.add(topic[0])
        
        #If this subject matter hasn't been covered yet, add it
        elif not (topic[0] in topic_titles):
            result.add(topic)
            topic_titles.add(topic[0])

#This shows the UI for talking to petunia
proc talkToShopUI(topics:seq[(string, string)], selection:int) = 
    stdout.eraseScreen()
    stdout.setCursorPos(0,0)
    #Start printing out some of the menu
    stdout.write(" ________________________________________\n")
    stdout.write("| Choose a topic (to ask Petunia about)\n")
    stdout.write("| Esc - Stop talking\n")
    stdout.write("| W / S - up/down through topics\n")
    stdout.write("| Enter - select topic\n|\n")

    var topic_num = 0 #Index for the selected topic

    for topic in topics:
        #Start of this topic listing
        stdout.write("| " & topic[0] & " (")

        #If slected, put asterisk here
        if topic_num == selection:
            stdout.write("*)\n")
        
        #Otherwise, empty parenthesis
        else:
            stdout.write(")\n")

        inc(topic_num) #Increase topic number
    
    #Print out end of the ui
    stdout.write("|________________________________________\n")

#This function deals with talking to Petunia about a topic
proc talkToShop(self:var Shop) = 
    #If player has talked to Petunia before, say she's not interested
    if self.hasTalked:
        stdout.eraseScreen()      #Clear out the screen
        let 
            size = terminalSize() #Get the size of the terminal
            #Text printed when she's not interested
            notInterested = "She's not interested in talking right now."
            continueText = "(Press Anything to Continue)"

        #Setup cursor to print out the not interested text
        stdout.setCursorPos(int(size[0]/2) - int(len(notInterested)/2), int(size[1]/2))
        stdout.write(notInterested) #Print out not interested text
        #Setup for printing continue text
        stdout.setCursorPos(int(size[0]/2) - int(len(continueText)/2), int(size[1]/2)+1)
        stdout.write(continueText) #Print out the text saying to continue

        discard getch() #Get a keypress, wait

    #Otherwise, try to talk to Petunia about something
    else:
        var 
            chr = '\0'    #Character input
            selection = 0 #Selected topic to talk about

        #While user doesn't quit out of menu
        while true:
            #Draw the user interface
            self.talkTopics.talkToShopUI(selection)
            chr = getch().toLowerAscii() #Get character input

            #If the player presses escape, close out menu
            if chr == '\x1b':
                break

            #If going up through selection, try to do so
            elif chr == 'w' and selection > 0:
                selection -= 1
            
            #If going down through slection, try to do so
            elif chr == 's' and selection < MAX_TOPIC_NUMBER:
                selection += 1
            
            #Player makes seleciton, print out description
            elif chr == '\r':
                self.hasTalked = true    #Mark that Petunia spoke
                stdout.eraseScreen()     #Erase the screen
                stdout.setCursorPos(0,0)
                #Print out all the text which is the response
                wrapEcho(self.talkTopics[selection][1])
                #Wait for response from user
                stdout.writeLine("\n(Press Anything to Continue)")
                discard getch()
                break

#Prints out all of the UI for the buying of things from the shop
proc buyFromShopUI(self:var Shop, dialog:var seq[string], selection, playerGold:int) =
    #Returns corresponding selection symbol for if selected
    func selectionSymbol(id, select: int): string =
        if id == select: result = "(*)"
        else: result = "()"

    stdout.eraseScreen() #Erase the screen
    stdout.setCursorPos(0,0)
    echo " ___________________________________________________"
    echo "| Petunia) Store"
    echo "| Esc   - exit store"
    echo "| W / S - move up/down through selection"
    echo "| Enter - buy selected item"
    echo "|"

    #Tell the user how much gold they have
    echo fmt"| Your Gold: {playerGold}"
    #Give info about the health potions
    echo fmt"| Health Potion ({self.potions}, {self.potionCost} gold each) {selectionSymbol(0, selection)}"
    #Give the information about the selected piece of armor
    sayItemText(self.armor, "| Armor: ", shPostfix=fmt" ({self.armorCost} gold) " & selectionSymbol(1, selection))
    #Give the information about the selected piece of weaponry 
    sayItemText(self.weapon, "| Weapon: ", shPostfix=fmt" ({self.weaponCost} gold) " & selectionSymbol(2, selection))

    echo "|___________________________________________________"

    #Write out all of the dialog
    dialog.writeDialog(55)
    #Clear out dialog since we're done with that
    dialog = @[]

#This is the option for buying things from the shop (Petunia)
proc buyFromShop(self:var Shop, player:var Player) =
    #Check if there are no potions, then cost is zero
    if self.potions == 0 and self.potionCost > 0:
        self.potionCost = 0

    var
        dialog: seq[string] = @[]
        selection = 0
        chr = '\0'
    
    while true:
        #Display the UI for this menu
        self.buyFromShopUI(dialog, selection, player.gold)
        chr = getch().toLowerAscii() #Get option

        #If player is exiting out, quit
        if chr == '\x1b':
            break

        #If going to previous item in selection, try
        elif chr == 'w' and selection > 0:
            selection -= 1
        
        #If going to next selection, try
        elif chr == 's' and selection < 2:
            selection += 1
        
        #If trying to buy something that is selected
        if chr == '\r':
            #If player trying to buy potion, and has money, give them it
            if selection == 0 and player.gold >= self.potionCost:
                #If there are actual potions to buy, buy them
                if self.potions > 0:
                    player.potions += 1
                    self.potions -= 1
                    player.gold -= self.potionCost
                    dialog.add("+1 health potion")

                    #If now no more potions, no more cost
                    if self.potions == 0: self.potionCost = 0
                
                #otherwise, cannot buy any
                else:
                    dialog.add("You can't buy nothing!")
            
            #If player trying to buy the armor, check if there is room in bag, or can be put on
            elif selection == 1 and player.gold >= self.armorCost and (self.armor of Armor):
                #If player not wearing armor, equip the bought piece
                if not (player.armor of Armor):
                    player.armor = self.armor                        #Give the player the armor
                    self.armor = GameItem(name:"None", desc:"")      #Give seller nothing
                    player.gold -= self.armorCost                    #Subtract cost from player
                    self.armorCost = 0                               #Update cost to 0
                    dialog.add(fmt"You equip the {self.armor.name}") #Tell player it is equipped
                
                #If we could instead stow it away into the bag
                elif len(player.inventory) < MAX_BAG_LENGTH:
                    player.inventory.add(self.armor)                  #Put the armor in bag
                    self.armor = GameItem(name:"None", desc:"")       #Give seller nothing
                    player.gold -= self.armorCost                     #Take cost of armor
                    self.armorCost = 0                                #Update cost to 0
                    dialog.add(fmt"{self.armor.name} is in your bag") #Tell player it is in bag
                
                #Otherwise, there is NO room to take it
                else:
                    dialog.add("You don't have any room!")

            #If player trying to buy the weapon, check if there is room in bag, or can be put on
            elif selection == 2 and player.gold >= self.weaponCost and (self.weapon of Weapon):
                #If player not wearing armor, equip the bought piece
                if not (player.weapon of Weapon):
                    player.weapon = self.weapon                       #Give the player the armor
                    self.weapon = GameItem(name:"None", desc:"")      #Give seller nothing
                    player.gold -= self.weaponCost                    #Subtract cost from player
                    self.weaponCost = 0                               #Set cost of weapon to 0
                    dialog.add(fmt"You equip the {self.weapon.name}") #Tell player it is equipped
                
                #If we could instead stow it away into the bag
                elif len(player.inventory) < MAX_BAG_LENGTH:
                    player.inventory.add(self.weapon)                  #Put the armor in bag
                    self.weapon = GameItem(name:"None", desc:"")       #Give seller nothing
                    player.gold -= self.weaponCost                     #Take cost of armor
                    self.weaponCost = 0                               #Set cost of weapon to 0
                    dialog.add(fmt"{self.weapon.name} is in your bag") #Tell player it is in bag
                
                #Otherwise, there is NO room to take it
                else:
                    dialog.add("You don't have any room!")
            
            #If user was trying to buy nothing, stop them!
            elif selection == 1 and not (self.armor of Armor) or selection == 2 and not (self.weapon of Weapon):
                dialog.add("You can't buy nothing!")
            
            #otherwise, not enough money
            else:
                dialog.add("You don't have enough money!")

#Draws out the user interface to the selling of items to shop
proc sellToShopUI(self:var Shop, dialog:var seq[string], player:var Player, selection:int) =
    stdout.eraseScreen()
    stdout.setCursorPos(0,0)

    echo " ________________________________________________________________"
    echo "| Petunia ) Sell Items"
    echo "| Esc   - exit menu"
    echo "| W / S - move up / down through selection"
    echo "| Enter - sell selected items"
    echo "| E     - sell all items"
    echo "|"
    echo fmt"| Your gold: {player.gold}"
    echo "|"

    #If the player has things in their bag, list them
    if len(player.inventory) > 0:
        #Go through each item in the player's inventory to print it out
        for i in 1..len(player.inventory):
            let item = player.inventory[i-1]

            #If this is the selected item, change second header postfix
            if selection == i:
                item.sayItemText(fmt"| {i}: ", "|  ", shPostfix=" (*)")
            
            else: #If this item not selected, have unselected item
                item.sayItemText(fmt"| {i}: ", "|  ", shPostfix=" ()")
    
    else: #Otherwise, nothing in bag
        echo "| Nothing is in your bag."

    echo " ________________________________________________________________"

    #Write out all the dialog
    dialog.writeDialog(66)
    #Clear out dialog buffer
    dialog = @[]

#This is the option for selling items to the shopkeep
proc sellToShop(self:var Shop, player:var Player) =
    #Gives price of item, has bonus for how intact item is
    proc sellPrice(item: GameItem): int =
        #Return normal cost of weapon, add bonus for how undamadged it is
        if item of Weapon:
            return getWeaponCost(Weapon item) + int((Armor item).health / 10)
        
        #Return normal cost of armor, plus bonus for how intact it is
        elif item of Armor:
            return getArmorCost(Armor item) + int((Armor item).health / 10)

    var 
        chr = '\0'
        selection = 1
        dialog: seq[string] = @[]

    while true:
        self.sellToShopUI(dialog, player, selection)
        chr = getch().toLowerAscii()

        #Close out menu when player presses escape
        if chr == '\x1b':
            break

        #Moving up through selection, only if not at first item
        elif chr == 'w' and selection > 1:
            selection -= 1
        
        #Move down through selection, only if not on final item
        elif chr == 's' and selection < len(player.inventory):
            selection += 1
        
        #Selling single item, remove that item
        elif chr == '\r' and len(player.inventory) > 0:
            #Calculate the amount the player will get by selling this
            let profit = sellPrice(player.inventory[selection-1])
            player.gold += profit #Add the earned money to bag

            var 
                index = 1
                newInventory: seq[GameItem] #New inventory after selling

            #Go through each item, only add those not being sold right now
            for item in player.inventory:
                if index != selection:
                    newInventory.add(item)
                
                index += 1
            
            #Give player new inventory where item is sold and gone
            player.inventory = newInventory
            #Tell player how much they profited by
            dialog.add fmt"+{profit} gold!"
        
        #Selling all items in bag, first ask if they want to do it
        elif chr == 'e' and len(player.inventory) > 0:
            #Gives all of the lines for this sub menu
            let lines = @[
                " _________________________________________________________",
                "|        Are you sure you want to sell everything?",
                "|                      (Y)es / (N)o",
                " ---------------------------------------------------------"
            ]
            
            #Make the popup menu to ask if the player is certain
            popupMenu(3, 5, lines)

            #Only allow for Escape, Y and N as inputs
            while not (chr in ['y', 'n', '\x1b']): chr = getch().toLowerAscii()

            #If the player said they are sure (they want to sell everything) do so
            if chr == 'y':
                #Calculate the total profit of player by selling everything
                let profit = sum(map(player.inventory, sellPrice))
                player.gold += profit  #Give player earned money
                player.inventory = @[] #Clear out inventory, no more items in bag
                #Tell player how much gold they just got
                dialog.add fmt"+{profit} gold!"
        
        #If trying to sell nothing, complain to the player
        elif chr == 'e' or chr == '\r' and len(player.inventory) == 0:
            dialog.add "You can't sell anything!"

#Returns the cost of repairing the item fully
func repairCost(item: GameItem): int =
    #Calculate repair cost: (WEAPON_COST / 1.5) - (100 - WEAPON_HEALTH)/5
    if item of Weapon:
        return int(float(getWeaponCost(Weapon item)) / 1.5 + (100 - (Weapon item).health) / 5)
    #Calculate repair cost: (ARMOR_COST / 1.5) - (100 - ARMOR_HEALTH)/5
    elif item of Armor:
        return int(float(getArmorCost(Armor item)) / 1.5 + (100 - (Armor item).health) / 5)

#This draws in the user interface for repairing items
proc repairItemsUI(self:var Shop, dialog:var seq[string], player:var Player, selection:int) =
    stdout.eraseScreen()
    stdout.setCursorPos(0,0)

    #Returns string of if this item is selected or not
    func selectionTag(id, selection: int): string =
        if id == selection:
            return "(*)"
        else:
            return "()"


    echo " ________________________________________________________________"
    echo "| Petunia ) Repair Items"
    echo "| Esc   - exit menu"
    echo "| W / S - move up/down through selection"
    echo "| Enter - repair selected item\n|"
    echo fmt"| Your Gold: {player.gold}"
    echo "|"

    #Show the propper text for if this item is nothing
    if isNoneObj(player.weapon):
        echo "| Equipped Weapon: None " & $selectionTag(1, selection)
    
    else: #Otherwise, also give info on how much it will cost
        echo "| Equipped Weapon: " & player.weapon.name & fmt" ({repairCost(player.weapon)} gp) " & $selectionTag(1, selection)
    
    #Show text for the equipped armor
    if isNoneObj(player.armor):
        echo "| Equipped Armor: None " & $selectionTag(2, selection)
    
    else: #Otherwise give all info
        echo "| Equipped Weapon: " & player.armor.name & fmt" ({repairCost(player.armor)} gp) " & $selectionTag(2, selection)
    
    #If there are things in the player's bag, add them
    if len(player.inventory) > 0:
        echo "| In your bag:"

        var selIndex = 3 #Selection index starts at 3

        #Go through the selection of every item, say their cost
        for item in player.inventory:
            echo fmt"{selIndex - 3} {item.name} ({repairCost(item)} gp) {selectionTag(selIndex, selection)}"
    
    #Otherwise, nothing to repair
    else:
        echo "| Nothing is in your bag."


    echo " ________________________________________________________________"

#This is the option for repairing any items (eqipped or otherwise)
proc repairItems(self:var Shop, player:var Player) =
    var
        chr = '\0'
        selection = 1
        dialog: seq[string]
    
    while true:
        self.repairItemsUI(dialog, player, selection)
        chr = getch().toLowerAscii()

        #If player presses escape, exit menu
        if chr == '\x1b':
            break

        #If scrolling up, and can do so, go one item up
        elif chr == 'w' and selection > 1:
            selection -= 1
        
        #If scrolling down, and can do so, go one item up
        elif chr == 's' and selection < (len(player.inventory) + 2):
            selection += 1
        
        #If trying to repair item (press enter)
        elif chr == 'r':
            var item: GameItem #The item attempting to be repaired

            #If the first selection, it is the armor
            if selection == 1:
                item = player.armor
            
            #If second, we're looking at weapon
            elif selection == 2:
                item = player.weapon
            
            #Otherwise, select it from the bag
            else:
                item = player.inventory[selection-3]

            #If the player has enough gold to repair this item
            if not isNoneObj(item) and player.gold >= repairCost(item):
                (Armor item).health = 100.0           #Give the item full health
                player.gold -= repairCost(item)       #Remove cost from player
                dialog.add fmt"Repaired {item.name}!" #Tell user it was repaired
            
            #Tell the user they didn't have enough gold to repair that item
            elif not isNoneObj(item) and player.gold < repairCost(item):
                dialog.add fmt"Not enough gold to repair {item.name}!"
            
            #Tell user they cannot repair nothing item
            elif isNoneObj(item):
                dialog.add "Can't repair nothing!"

#Draw the basic UI for the toplevel menu for shops
proc shopkeepUI*(self:var Shop) =
    #Clear screen and set cursor positions
    stdout.eraseScreen()
    stdout.setCursorPos(0, 0)
    echo " ____________________________________"
    echo "| Petunia) What do you wanna do?"
    echo "| Esc - exit shop\n|"
    echo "| Buy items (Q)"
    echo "| Sell items (E)"
    echo "| Talk to Petunia (F)"
    echo "|____________________________________\n"

#The main function that deals with all sorts of interactions with the shop
proc shopInteraction*(self:var Shop, player:var Player) =
    #[
        Petunia) What do you wanna do?
        Esc - stop interacting with petunia

        Buy items (Q)
        Sell items (E)
        Repair items (R)
        Talk to Petunia (F)
    ]#

    var chr = '\0' 

    #Continue this menu while still interacting with it
    while true:
        self.shopkeepUI()
        chr = getch().toLowerAscii() #Get single character input

        #If/when the player presses escape, close menue
        if chr == '\x1b':
            break

        #If trying to talk to petunia, try to do so
        elif chr == 'f':
            self.talkToShop()
        
        #If trying to buy from the shop
        elif chr == 'q':
            self.buyFromShop(player)
        
        #If trying to sell things to shop
        elif chr == 'e':
            self.sellToShop(player)
        
        #If trying to repair some items
        elif chr == 'r':
            self.repairItems(player)
