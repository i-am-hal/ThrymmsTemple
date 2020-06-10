#[
This is the Downward Descent game- this has the start
of the game with the main menu.
Author: Alastar Slater
Date: 9/28/2019
]#

from times import getTime, toUnix, nanosecond
from strutils import toLowerAscii
import terminal, gameModes, random

#The user interface for the main menu
proc thrymmsTempleUI =
  stdout.eraseScreen() #Clear out screen and center cursor
  stdout.setCursorPos(0,0)

  echo " ______________________________"
  echo "| Thrymms Temple - Version 0.5 "
  echo "|------------------------------"
  echo "| (Q)uit                       "
  echo "| (S)tory mode                 "
  echo "|______________________________"

#Entry point for the game
proc main =
  enableTrueColors()  #Try to allow for true colors
  let now = getTime() #Get current system time
  randomize(now.toUnix * 1000000000 + now.nanosecond) #Makes sure all seeds are random
  stdout.hideCursor() #Hide the cursor
  #Make all the text white before starting
  stdout.setForegroundColor(fgWhite)

  var chr = '\0' #Character input from user

  #The main loop for the top level menu for the game
  while true:
    thrymmsTempleUI()
    chr = getch().toLowerAscii()

    #Quits game
    if chr == 'q' or chr == '\x1b':
      break
    
    #Start the story mode
    elif chr == 's':
      storyMode()

  disableTrueColors()      #Turn off true color
  stdout.showCursor()      #Show the cursor
  stdout.eraseScreen()     #Erase the screen
  stdout.setCursorPos(0,0) #Set cursor position

#Start the main function when being ran
when isMainModule:
  main()
  