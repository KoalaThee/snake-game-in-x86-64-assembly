# snake-game-in-x86-64-assembly
This project is a snake game implemented in x86-64 assembly language using AT&T syntax. The game is run in a terminal and utilizes the ncurses library for rendering the game board and handling user input. Players control a snake that grows by eating apples while avoiding collisions with its own body. The game includes features such as increasing speed, collision detection, and a timer-based gameplay mechanic.

## Running the Game:
1. Install dependencies:

2. Clone or download the repository.
   
3. Compile the game:
  ```
  make
  ``` 
4. Run the game:
  ```
./snake <snake_length> <num_apples>
  ```

## Features Supported:
### Game Initialisation:
- The game initializes a 10x10 grid using ncurses.
- The snake starts at the center of the board with the specified length, and apples are placed randomly in positions not occupied by the snake.

### Keyboard Input:
- Control the snake using the arrow keys.
- If no valid key is pressed, the snake will continue in the same direction.
- Invalid or undefined keys are ignored.

### Snake Movements:
- The snake moves in one direction, updating its head position while the tail follows.
- Crossing the board boundary wraps the snake to the opposite side.

#### Apple Placement:
- Apples are placed randomly in positions not occupied by the snake or other apples.
- New apples appear immediately after one is eaten.

### Snake Growth:
- Eating an apple increases the snake's length, which is reflected in its movements.

### Timer:
- A timer limits the game duration. If it expires, the game ends.
- The timer resets each time an apple is eaten.

### Speed Increase:
- The snake's speed increases every time an apple is eaten by reducing the delay between movements.

### Collision Detection:
- The game ends if the snake collides with its own body.

## Key Components:
### Variable Management:
- Snake Position: Stored in arrays for x and y coordinates with pointers to track the head and tail.
- Apple Position: Stored in arrays for x and y coordinates, with checks to avoid overlapping with the snake.

### Game Initialization:
- The board is set up using the board_init function (from helper.c).
- Borders are drawn, and the snake and apples are initialized.

### Game Loop:
- Handles user input, updates snake position, detects collisions, and redraws the screen.
- Includes a delay (usleep) between iterations to control the snake's speed.

### Direction Handling:
- Direction is determined by the last valid keypress.
- Functions for each direction ensure the snake moves in valid ways without reversing.

### Apple Placement:
- Randomized positions are checked to ensure they don't overlap with the snake or other apples.

### Collision Detection:
- Body collisions are detected by checking the snake's head against its body array.

### Speed Control:
- Movement delay decreases by 0.025 seconds every time an apple is eaten, increasing the game difficulty.

### Game Termination:
- The game ends if the timer expires or the snake collides with its body. The board is cleared using game_exit.

## Author
Developed by Patteera Lerdtada, Xuning Zhang, Thee Kullatee.
