#[
This is the Downward Descent game- this has the start
of the game with the main menu.
Author: Alastar Slater
Date: 9/28/2019
]#

from times import getTime, toUnix, nanosecond
import terminal, gameModes, random

proc main =
  let now = getTime() #Get current system time
  randomize(now.toUnix * 1000000000 + now.nanosecond) #Makes sure all seeds are random
  stdout.hideCursor() #Hide the cursor
  #Make all the text white before starting
  stdout.setForegroundColor(fgWhite)
  stdout.eraseScreen() #Clear the screen before starting
  stdout.setCursorPos(0,0)

  storyMode() #Start the story mode

  stdout.showCursor()      #Show the cursor
  stdout.eraseScreen()     #Erase the screen
  stdout.setCursorPos(0,0) #Set cursor position

#Start the main function when being ran
when isMainModule:
  main()
  