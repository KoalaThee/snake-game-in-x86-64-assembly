.section .bss
    # Reserve 8 bytes for each variable
	.lcomm snake_len, 8
	.lcomm board_side, 8
	.lcomm num_apples, 8
	.lcomm snake_x_pos, 8
	.lcomm snake_y_pos, 8
	.lcomm key, 8
	.lcomm snake_head, 8
	.lcomm current_apples, 8
	.lcomm snake_end, 8
	.lcomm apple_status, 2
	.lcomm horizontal_status, 8
	.lcomm vertical_status, 8
	.lcomm game_delay, 8
	.lcomm game_timer, 8
	.lcomm game_time_limit, 8

	# Reserve 8000 bytes (500 moves) for snake movements
	.lcomm snake_x_positions, 4000	# Snake X positions (500 segments, 8 bytes each)
	.lcomm snake_y_positions, 4000	# Snake Y positions (500 segments, 8 bytes each)

	# Reserve 816 bytes for a maximum of 50 apples
	.lcomm apple_x_positions, 408   	# X position of the apple
	.lcomm apple_y_positions, 408   	# Y position of the apple

.section .text # Define global and external labels and functions
.global start_game
.extern usleep       # Tell the assembler that usleep is an external function
.extern rand         # Tell the assembler that rand is an external function

# Function to start the game
start_game:
    # Set up stack frame
    push %rbp
    movq %rsp, %rbp
    sub $32, %rsp

    # Initialise variables to store game information
    movq %rdi, snake_len
    movq snake_len, %rax
    movq $10, board_side
    movq %rsi, num_apples

    # Align stack and call external function board_init from helpers.c
    sub $8, %rsp
    and $-16, %rsp
    call board_init
    add $8, %rsp

    # Initialise snake, apples and borders on the screen
    movq %rdi, %rbx
    call init_snake
    movq %rsi, %rbx
    call init_apples
    call print_board

    # Initialise variables to keep track of current snake direction
    movq $2, horizontal_status
    movq $2, vertical_status

    # Initialise variables to keep track of time (delay and timer)
    movq $1000000, game_delay
    movq $0, game_timer
    movq board_side, %rax
    imulq %rax, %rax
    movq %rax, game_time_limit

    # Set Initial direction to be downwards
    movq $258, %r13         # r13 is last direction travelled
    movq $-1, %r12          # r12 is key pressed

# Main loop to play the snake game
main_loop:
    # Increment timer for each move made
    movq game_timer, %rax
    incq %rax
    movq %rax, game_timer
    cmpq game_time_limit, %rax
    je exit_game            # Exit game if timer reaches the set limit

    # Get the key pressed by keyboard
    sub $8, %rsp
	call board_get_key
	add $8, %rsp
	movq %rax, %r12

	# Check and move if it's a valid key (up, down, left, or right)
	cmpq $258, %r12
	je move_down
	cmpq $259, %r12
	je move_up
	cmpq $260, %r12
	je move_left
	cmpq $261, %r12
	je move_right

	# Set key pressed to -1 if invalid key recieved (maintain direction from previous direction travelled)
	movq $-1, %rax
	movq %r13, %r12

	# Continue moving based on last direction travelled
	cmpq $258, %r12
	je move_down
	cmpq $259, %r12
	je move_up
	cmpq $260, %r12
	je move_left
	cmpq $261, %r12
	je move_right

# Delay game loop using usleep
delay:
	movq game_delay, %rdi
	call usleep
	jmp main_loop               # Continue the game loop

# Draws borders on the screen
print_board:
    # Assume board_side holds the width/height of the board
    movq board_side, %r12
    addq $1, %r12
    movq $0, %r13               # Set top border
    call draw_horizontal_border
    movq %r12, %r13             # Set bottom border
    call draw_horizontal_border
    movq $0, %r14               # Set left border
    call draw_vertical_border
    movq %r12, %r14             # Set right border
    call draw_vertical_border
    ret

# Draw horizontal borders
draw_horizontal_border:
    movq $1, %r14
loop_horizontal_border:
    cmpq %r12, %r14
    je call_return
    movq %r13, %rsi
    movq %r14, %rdi
	movb $'-', %dl
	subq $8, %rsp
	call board_put_char
	addq $8, %rsp
	incq %r14
	jmp loop_horizontal_border

# Draw vertical borders
draw_vertical_border:
    movq $1, %r13
loop_vertical_border:
    cmpq %r12, %r13
    je call_return
    movq %r13, %rsi
    movq %r14, %rdi
	movb $'|', %dl
	subq $8, %rsp
	call board_put_char
	addq $8, %rsp
	incq %r13
	jmp loop_vertical_border

# Down movement function
move_down:
    cmpq $0, vertical_status    # Reset key input if up direction pressed
    je main_loop
    call reprint_head1          # Unprint head

    # Update snake x position
    incq snake_head
    movq snake_head, %r14
    movq snake_x_pos, %r15
    movq %r15, snake_x_positions(,%r14, 8)
    movq snake_y_pos, %r15
    incq %r15
    # Check if border is reached and move position to the other side
    movq board_side, %r9
    incq %r9
    cmpq %r15,%r9
    jne down2
    movq $1, %r15
    down2:
    # Update snake y position
	movq %r15, snake_y_positions(,%r14, 8)
    movq %r15, snake_y_pos

    # Check collision with snake body for exit
    call check_body_collision

    # Check if snake head collides with apple
    call check_apple_collision

    # Reprint snake head
	call reprint_head2

	# Check apple status, if found, do not decrease snake length (snake grows)
    movq apple_status, %rax
    cmpq $1, %rax
    je down1
	call unprint_tail # Unprint the tail (last snake position)
	down1:

	# Reset variables
    movq $258, %r13
    movb $0, apple_status
    movq $1, vertical_status
    movq $2, horizontal_status
    jmp delay # Delay

# Up movement function
move_up:
    cmpq $1, vertical_status # Reset key input if down direction pressed
    je main_loop
    call reprint_head1       # Unprint head

    # Update snake x position
    incq snake_head
    movq snake_head, %r14
    movq snake_x_pos, %r15
    movq %r15, snake_x_positions(,%r14, 8)
    movq snake_y_pos, %r15
    decq %r15

    # Check if border is reached and move position to the other side
    movq $0, %r9
    cmpq %r15,%r9
    jne up2
    movq board_side, %r15
    up2:
    # Update snake y position
	movq %r15, snake_y_positions(,%r14, 8)
    movq %r15, snake_y_pos

    # Check collision with snake body for exit
    call check_body_collision

    # Check if snake head collides with apple
    call check_apple_collision

    # Reprint snake head
	call reprint_head2

    # Check apple status, if found, do not decrease snake length (snake grows)
    movq apple_status, %rax
    cmpq $1, %rax
    je up1
	call unprint_tail # Unprint the tail (last snake position)
	up1:

	# Reset variables
    movq $259, %r13
    movb $0, apple_status
    movq $0, vertical_status
    movq $2, horizontal_status
    jmp delay

# Left movement function
move_left:
    cmpq $1, horizontal_status  # Reset key input if right direction pressed
    je main_loop
    call reprint_head1  # Unprint head

    # Update snake x position
    incq snake_head
    movq snake_head, %r14
    movq snake_x_pos, %r15
    decq %r15

    # Check if border is reached and move position to the other side
    movq $0, %r9
    cmpq %r15,%r9
    jne left2
    movq board_side, %r15
    left2:
    # Update snake y position
    movq %r15, snake_x_pos
    movq %r15, snake_x_positions(,%r14, 8)
    movq snake_y_pos, %r15
	movq %r15, snake_y_positions(,%r14, 8)

	# Check collision with snake body for exit
	call check_body_collision

	# Check if snake head collides with apple
    call check_apple_collision

    # Reprint snake head
	call reprint_head2

    # Check apple status, if found, do not decrease snake length (sna  # Load apple_status into %rax
    cmpq $1, %rax
    je left1
	call unprint_tail  # Unprint the tail (last snake position)
	left1:

	# Reset variables
    movq $260, %r13
    movb $0, apple_status
    movq $0, horizontal_status
    movq $2, vertical_status
    jmp delay

# Right movement function
move_right:
    cmpq $0, horizontal_status 	# Reset key input if left direction pressed
    je main_loop
    call reprint_head1 # Unprint head

    # Update snake x position
    incq snake_head
    movq snake_head, %r14
    movq snake_x_pos, %r15
    incq %r15
    # Check if border is reached and move position to the other side
    movq board_side, %r9
    incq %r9
    cmpq %r15,%r9
    jne right2
    movq $1, %r15
    right2:
    # Update snake y position
    movq %r15, snake_x_pos
    movq %r15, snake_x_positions(,%r14, 8)
    movq snake_y_pos, %r15
	movq %r15, snake_y_positions(,%r14, 8)

	# Check collision with snake body for exit
	call check_body_collision

	# Check if snake head collides with apple
    call check_apple_collision

    # Reprint snake head
	call reprint_head2

    # Check apple status, if found, do not decrease snake length (snake grows)
    movq apple_status, %rax
    cmpq $1, %rax
    je right1
	call unprint_tail # Unprint the tail (last snake position)
	right1:

	# Reset variables
    movq $261, %r13
    movb $0, apple_status
    movq $1, horizontal_status
    movq $2, vertical_status
    jmp delay

# Function to unprint head (change head to body)
reprint_head1:
    # load current head position
    pushq %rbp
    mov %rsp, %rbp
    movq $1, %r12
    movq snake_x_pos, %rdi
    movq snake_y_pos, %rsi
    movb $'O', %dl
    subq $8, %rsp
    call board_put_char # print '0' (body) to replace 'X' (head)
    addq $8, %rsp
    popq %rbp
    ret

# Function to print new head ('X')
reprint_head2:
    # load new head position
    pushq %rbp
    mov %rsp, %rbp
    movq $1, %r12
    movq snake_x_pos, %rdi
    movq snake_y_pos, %rsi
    movb $'X', %dl
    subq $8, %rsp
    call board_put_char # Print 'X' at new head position
    addq $8, %rsp
    popq %rbp
    ret

# Unprint the tail as the snake moves
unprint_tail:
    # load end position of the snake
    pushq %rbp
    movq %rsp, %rbp
    movq snake_end, %r14
    movq snake_x_positions(,%r14, 8), %rdi
    movq snake_y_positions(,%r14, 8), %rsi
    movb $' ', %dl
    subq $8, %rsp
    call board_put_char # Print blank at the end position of the snake
    addq $8, %rsp
    incq snake_end # Increment the snake end index (may wrap around)
    popq %rbp
    ret

# Initialise snake
init_snake:
    # Calculate the initial position of the snake
    movq board_side, %rax
    shrq $1, %rax
    addq $1, %rax
    movq %rax, snake_y_pos 	# Set Y position to the middle of the board
    movq board_side, %rbx
    shrq $1, %rbx
    addq $1, %rax
    movq %rbx, snake_x_pos 	# Set X position to the middle of the board

    # load snake position and variables
    movq snake_x_pos, %rdi
    movq snake_y_pos, %rsi
    movq snake_len, %r15
    movq %r15, snake_head

loop:
    # loop to store x and y positions
    movq %rdi, %r12
    movq %rsi, %r13
    movb $'O', %dl
	movq %r12, snake_x_positions(,%r15, 8)  # Store X position in snake_x_positions
	movq %r13, snake_y_positions(,%r15, 8)  # Store Y position in snake_y_positions
    call board_put_char # Print body
    movq %r13, %rsi
    movq %r12, %rdi
    dec %rsi
	dec %r15
    jnz loop # loop to print whole body
    movq $1, snake_end
    ret

# initialise apples
init_apples:
    # load initial variables
    movq num_apples, %rbx
    movq %rbx, current_apples
	movq $1, %r13

place_apples:
    cmpq $0, %rbx
    je call_return # Check if all apples are placed on the board

    # Generate random apple position
    call rand
    mov %rax, %rdx
    mov board_side, %rcx
    xor %rdx, %rdx
    div %rcx
    add $1, %rdx
    mov %rdx, %r12
    call rand
    mov %rax, %rdx
    mov board_side, %rcx
    xor %rdx, %rdx
    div %rcx
    add $1, %rdx
    mov %rdx, %rsi
    mov %r12, %rdi

    # check positions to prevent collision with another apple
    movq $1, %r15
    place_apple_check:
    movq num_apples, %rcx
	cmpq %rcx, %r15
	jg place_apple_check22
    movq apple_x_positions(,%r15, 8), %r8
	movq apple_y_positions(,%r15, 8), %r9
    cmpq %rdi, %r8
	jne place_apple_check_temp
	cmpq %rsi, %r9
	jne place_apple_check_temp
    jmp place_apples # Regenerate position
    place_apple_check_temp:
    incq %r15
    jmp place_apple_check

    # check positions to prevent collision with the snake
    place_apple_check22:
    movq snake_end, %r15
    place_apple_check2:
    movq snake_head, %rcx
	cmpq %rcx, %r15
	jg place_apples_exit
    movq snake_x_positions(,%r15, 8), %r8
	movq snake_y_positions(,%r15, 8), %r9
    cmpq %rdi, %r8
	jne place_apple_check2_temp
	cmpq %rsi, %r9
	jne place_apple_check2_temp
    jmp place_apples # Regenerate position
    place_apple_check2_temp:
    incq %r15
    jmp place_apple_check2

    place_apples_exit:
    # Store the generated apple position in the arrays
	movq %rdi, apple_x_positions(,%r13, 8)
	movq %rsi, apple_y_positions(,%r13, 8)

    # Print new apple on the board
    mov $'A', %rdx
    movq %rbx, %r12
    call board_put_char
    movq %r12, %rbx
    inc %r13
    dec %rbx
    jmp place_apples # place the new apple

# return function
call_return:
    ret

check_apple_collision:
    # Load current positions of the snake's head
    movq snake_x_pos, %rdi
    movq snake_y_pos, %rsi

    # Check head position with all apple positions
    movq $1, %r14
check_next_apple:
    movq num_apples, %rcx
    cmpq %rcx, %r14
    jg call_return
    movq apple_x_positions(,%r14, 8), %r8
    movq apple_y_positions(,%r14, 8), %r9
    cmpq %rdi, %r8
    jne check_next_apple_temp # Loop again if apple position not matched
    cmpq %rsi, %r9
    jne check_next_apple_temp # Loop again if apple position not matched

# Run if apple is found
eat_apple:
    movb $1, apple_status
    movq $0, game_timer # reset the game timer
    pushq %rbp
    movq %rsp, %rbp
    movq %r8, %rdi
    movq %r9, %rsi
    movb $' ', %dl
    movq %rcx, %r15
    subq $8, %rsp
    call board_put_char # Unprint to remove the initial apple
    movq %r15, %rcx
    addq $8, %rsp
    popq %rbp

    # update variables
    incq snake_len
    decq current_apples

    # update game delay to increase game sped
    movq game_delay, %rax
    subq $25000, %rax
    jl skip_delay_update
    movq %rax, game_delay
skip_delay_update:
    jmp check_apple_count
    movq %rcx, %r13

# compare initial and expected apple count
check_apple_count:
    movq current_apples, %r8
    cmpq num_apples, %r8
    jge call_return

# generate new apple position randomly
generate_apple:
    call rand
    mov %rax, %rdx
    mov board_side, %rcx
    xor %rdx, %rdx
    div %rcx
    add $1, %rdx
    mov %rdx, %r12
    call rand
    mov %rax, %rdx
    mov board_side, %rcx
    xor %rdx, %rdx
    div %rcx
    add $1, %rdx
    mov %rdx, %rsi
    mov %r12, %rdi
    movq $1, %r15

    # check positions to prevent collision with another apple
    generate_apple_check:
    movq num_apples, %rcx
	cmpq %rcx, %r15
	jg generate_apple_check22
    movq apple_x_positions(,%r15, 8), %r8
	movq apple_y_positions(,%r15, 8), %r9
    cmpq %rdi, %r8
	jne generate_apple_check_temp
	cmpq %rsi, %r9
	jne generate_apple_check_temp
    jmp generate_apple # Regenerate position
    generate_apple_check_temp:
    incq %r15
    jmp generate_apple_check

    # check positions to prevent collision with the snake
    generate_apple_check22:
    movq snake_end, %r15
    generate_apple_check2:
    movq snake_head, %rcx
	cmpq %rcx, %r15
	jg generate_apples_exit
    movq snake_x_positions(,%r15, 8), %r8
	movq snake_y_positions(,%r15, 8), %r9
    cmpq %rdi, %r8
	jne generate_apple_check2_temp
	cmpq %rsi, %r9
	jne generate_apple_check2_temp
    jmp generate_apple # Regenerate position
    generate_apple_check2_temp:
    incq %r15
    jmp generate_apple_check2

    generate_apples_exit:
	# Store the generated apple position in the arrays
	movq %rdi, apple_x_positions(,%r14, 8)
	movq %rsi, apple_y_positions(,%r14, 8)
    # incq num_apples

    # Print new apple on the board
    mov $'A', %dl
    call board_put_char
    incq current_apples
    movq current_apples, %r8
    cmpq %r8, num_apples
    jl generate_apple
    movq snake_x_pos, %rdi
    movq snake_y_pos, %rsi
check_next_apple_temp:
    inc %r14
    jmp check_next_apple

# Check for collision with snake body
check_body_collision:
    movq snake_end, %r14
loop_body_check:
    movq snake_x_pos, %rdi
    movq snake_y_pos, %rsi
    movq snake_head, %rdx
    cmpq %rdx, %r14
    je call_return # If no collision, return
    movq snake_x_positions(,%r14, 8), %r8
    movq snake_y_positions(,%r14, 8), %r9
    cmpq %rdi, %r8              # Compare head y with body y
    jne check_next_segment_temp
    cmpq %rsi, %r9              # Compare head y with body y
    je exit_game2 # if position matches, move to exit game

check_next_segment_temp:
    incq %r14
    movq snake_x_pos, %rdi
    movq snake_y_pos, %rsi
    jmp loop_body_check               # Repeat check

# Close ncurses screen and end program
exit_game:
    subq $8, %rsp
    call game_exit
    addq $8, %rsp

# Close ncurses screen and end program
exit_game2:
    call game_exit
