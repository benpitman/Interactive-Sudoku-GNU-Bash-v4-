# Interactive Sudoku

## Basic Information
This script is purely written in Bash and is useable by any kernel running version 4 and above. The reason behind this is because the use of associated arrays is imperative. No installation instructions are needed; the script can be run directly from a terminal with `bash Sudoku.sh`, or it can be made executable using `chmod` and run by double-clicking (if that functionality has been enabled).

## Game Details
When the script is run, a gnome-terminal window is opened with the main menu displayed. Using the arrow keys to navigate all menus, the game begins when a difficulty is chosen. When the puzzle displays, the timer starts and the user can fill in the blank squares. At any point during the game certain control keys can be used to display different menus. The "C", "Q" and "R" buttons display a mini menu below the puzzle which does not stop the timer; however the "H" and "P" buttons impose the pause screen fully over the puzzle so the timer pauses with it. Additionally, you can now change the colour of your cursor and the numbers you place down. this can just be a personal colour preference, or so you can switch when guessing so you know which ones to delete if you were wrong.

## Code Details
The operations are segregates into individual functions so that they are performed only when necessary, with the exception of the menu systems. Unfortunately, due to the nature of the display, the menus are too specific to have in a function, hence why the script is longer than I would like it.

Upon selecting start from the main menu and a difficulty level from the next; the game begins building the 9x9 grid with random numbers from left-to-right and top-to-bottom. With each test of a new number, it builds an array of numbers from 1-9 in random order and checks each one in turn against all its horizontal, vertical and 3x3 block neighbours. When an available number is found, the loop starts again as a nest. If however, when it has cycled through all nine numbers and found no possibilities, the loop closes and the parent loop tries again for a new number. This continues until the puzzle has been filled; afterwhich, a copy is saved as a text file in the /tmp folder as the answer.

Random numbers for each block is then selected to be removed, and then added to another associative list so that the grid values that already have numbers in are protected against change. A copy of the edited grid is saved in case the user wishes to reset their progress. The timer begins and the puzzle is displayed on the screen.

Arrow key movements are identified with three `read`s to capture all characters from the button press. when the cursor is moved, the screen is reset with the styling in a new position; the same applies for when a number key is pressed. Otherwise the `read` will timeout and will refresh the screen anyway to update the timer.

When the user wishes to check their results, a copy of the puzzle is sent to the /tmp folder with all the formatting removed. If it is incorrect, the grid will turn red and the user can continue, otherwise the screen will go green and the user can either restart with a new grid at the same difficulty level, or they can return to the main menu.
