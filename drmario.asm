################# CSC258 Assembly Final Project ###################
# This file contains our implementation of Dr Mario.
#
# Student 1: Name, Student Number
# Student 2: Name, Student Number (if applicable)
#
# We assert that the code submitted here is entirely our own 
# creation, and will indicate otherwise when it is not.
#
######################## Bitmap Display Configuration ########################
# - Unit width in pixels:       8
# - Unit height in pixels:      8
# - Display width in pixels:    256
# - Display height in pixels:   256
# - Base Address for Display:   0x10008000 ($gp)
##############################################################################

    .data
##############################################################################
# Immutable Data
##############################################################################
# The address of the bitmap display. Don't forget to connect it!
ADDR_DSPL:
    .word 0x10008000
# The address of the keyboard. Don't forget to connect it!
ADDR_KBRD:
    .word 0xffff0000
# The address of the initial position of the capsule
CAPSULE_INIT_POS:
    .word 0x10008334  # ADDR_DSPL + 820
# # The address of a queue of 6 upcomming capsules (48 bytes in total). The values are their colors  
# ADDR_CAPSULE_QUEUE:
    # .word 0x10009000
    
RED:
    .word 0xff0000
BLUE:
    .word 0x0000ff
YELLOW:
    .word 0xffff00
BLACK:
    .word 0x000000
    
HEIGHT:
    .word 0x000018
WIDTH:
    .word 0x000011
START:
    .word 0x000614
    
# game states
GAME_OVER:  # game over
    .word 0
READY:  # get the next capsule
    .word 1
ENTERING:  # move the capsule into the bottle
    .word 2
FALLING:  # player can control the capsule
    .word 3
    

##############################################################################
# Mutable Data
##############################################################################

##############################################################################
# Code
##############################################################################
	.text
	.globl main

    # Run the game.
main:
    # Initialize the game
    addi $s6, $zero, 1  # s6 repr the game state, 1 is ready state
    addi $s7, $zero, 0  # fps counter
    
    j draw_bottle  # will jump to init_capsules

game_loop:
    # 1a. Check if key has been pressed
    # 1b. Check which key has been pressed
    lw $t0, ADDR_KBRD               # $t0 = base address for keyboard
    lw $t8, 0($t0)                  # Load first word from keyboard
    beq $t8, 1, keyboard_input      # If first word 1, key is pressed

    # draw the upcomming capsules
    addi $t0, $sp, -16
    lw $t1, CAPSULE_INIT_POS
    addi $t1, $t1, 56
    li $t2, 0  # loop counter
    jal draw_capsule_queue

    # # handle game states
    # lw $t1, READY
    # beq $s6, $t1, handle_ready_state
    
    # 60 fps
    li $v0, 32
    li $a0, 16
    syscall  # sleeps for ~1/60s
    
    # handle fps counter, # s7 == 60 => update capsule position
    addi $s7, $s7, 1
    bne $s7, 60, skip_gravity 
    addi $s7, $zero, 0
    # TODO move capsule down
    # TODO remove print
    li $v0, 1
    li $a0, 1
    syscall
    
handle_ready_state:
    # TODO carry over a capsule from stack
    lw $s6, ENTERING
    j game_loop
    
handle_entering_state:
    # animation for capsule to move into bottle
    lw $t0, CAPSULE_INIT_POS
    
    li $v0, 32
    li $a0, 1000
    syscall
    
    addi $s7, $zero, 0  # reset fps counter to avoid sudden changes due to previous fps values
    j game_loop
    
skip_gravity:
    # TODO remove print
    li $v0, 1
    li $a0, 0
    syscall
    j game_loop
    
draw_bottle:
    li $t2, 0x808080 # color of bottle
    lw $t3, ADDR_DSPL # initial address
    
    # t0: repr starting pos to draw pixel
    # a0: repr how many pixels to draw
    # t1: repr the counter
    
    # increment the column first, then offset the row for the starting position
    # the game board size is 17 * 24, and the bottle is 3 squares from the border
    addi $t0, $t3, 1024
    addi $t0, $t0, 20
    li $t1, 0
    li $a0, 6
    jal draw_line_row
    
    addi $t0, $t3, 1024
    addi $t0, $t0, 64
    li $t1, 0
    li $a0, 6
    jal draw_line_row
    
    addi $t0, $t3, 7424
    addi $t0, $t0, 20
    li $t1, 0
    li $a0, 17
    jal draw_line_row
    
    addi $t0, $t3, 512
    addi $t0, $t0, 44
    li $t1, 0
    li $a0, 3
    jal draw_line_column

    addi $t0, $t3, 512
    addi $t0, $t0, 60
    li $t1, 0
    li $a0, 3
    jal draw_line_column
    
    addi $t0, $t3, 1024
    addi $t0, $t0, 16
    li $t1, 0
    li $a0, 26
    jal draw_line_column
    
    addi $t0, $t3, 1024
    addi $t0, $t0, 88
    li $t1, 0
    li $a0, 26
    jal draw_line_column
    
    j init_capsules
    
draw_line_row:
    beq $t1, $a0, back_to_draw_bottle
    sw $t2, 0($t0)
    addi $t0, $t0, 4
    addi $t1, $t1, 1
    j draw_line_row
    
draw_line_column:
    beq $t1, $a0, back_to_draw_bottle
    sw $t2, 0($t0)
    addi $t0, $t0, 256
    addi $t1, $t1, 1
    j draw_line_column
    
back_to_draw_bottle: jr $ra

finish_keyboard_input:
    
    # 2a. Check for collisions
	# 2b. Update locations (capsules)
	# 3. Draw the screen
	
	# 4. Sleep
	li 		$v0, 32
	li 		$a0, 1
	syscall

    # 5. Go back to Step 1
    j game_loop

keyboard_input:                     # A key is pressed
    lw $a0, 4($t0)                  # Load second word from keyboard
    beq $a0, 0x71, respond_to_Q     # Check if the key q was pressed
    beq $a0, 0x57, respond_to_W     # Check if the key w was pressed
    beq $a0, 0x41, respond_to_A     # Check if the key a was pressed
    beq $a0, 0x53, respond_to_S     # Check if the key s was pressed
    beq $a0, 0x44, respond_to_D     # Check if the key d was pressed

    # li $v0, 1                       # ask system to print $a0
    # syscall

    j finish_keyboard_input

respond_to_Q:
    li $v0, 10                      # Quit gracefully
	syscall
	
	b finish_keyboard_input

# rotate capsule by 90 degrees clockwise 
respond_to_W:
    lw $t0, 0($a0)

# move capsule to the left
respond_to_A:
    lw $t0, 0($a0)      # coordinate 1 in matrix
    lw $t1, 0($a1)      # coordinate 2 in matrix
    lw $t2, HEIGHT      # HEIGHT
    lw $t3, WIDTH       # WIDTH 
    lw $t4, START       # START

respond_to_A_vertical_horizontal:
    addi $t5, $t0, -4   # subtarct 4 from capsule 1 value
    div $t0, $t2        # divide coordinate 1 by HEIGHT
    mflo $t6            # store quotient (height)

    mult $t6, $t3       # multiply coordinate 1 height and WIDTH to get leftmost address at that height
    mflo $t6            # store leftmost address at that height

    slt $t7, $t5, $t6   # check if resulting capsule coordinate 1 is less than leftmost address at that height
    bne $t7, $zero, finish_keyboard_input   # no space for capsule to go left, return
    
    addi $t8, $t1, -4   # subtarct 4 from capsule 2 value
    
    sw $t5, 0($a0)      # update memory to store updated coordinate 1
    sw $t8, 0($a1)      # update memory to store updated coordinare 2
    
    j finish_keyboard_input
    
# move capsule all the way to the bottom
respond_to_S:
    lw $t0, 0($a0)      # coordinate 1 in matrix
    lw $t1, 0($a1)      # coordinate 2 in matrix
    lw $t2, HEIGHT      # HEIGHT
    lw $t3, WIDTH       # WIDTH 
    lw $t4, START       # START

respond_to_S_get_lowest_coordinate:
# returns lowest y coordinate based on width of input
# result in $a2
    div $t0, $t2        # divide coordinate 1 by HEIGHT
    mfhi $t5            # store quotient (width)
    
    mult $t4, $t2       # multiply START and HEIGHT to reach last row
    mflo $t6            # store address of last row
    add $a2, $t6, $t5   # reach and store the particular pixel in the last row
    
    jr $ra
    
respond_to_S_vertical:
    jal respond_to_S_get_lowest_coordinate
    
    lw $t5, 0($a2)      # get return value of respond_to_S_get_lowest_coordinate
    
    add $t6, $t5, $zero # copy return value into iterator variable
    
respond_to_S_vertical_while: 
    slt $t7, $t6, $t4                       # if current pixel < START
    bne $t7, $zero, finish_keyboard_input   # if current pixel < START, end while loop
    
    # TODO Jai
    sub $t6, $t6, $t3                       # subtract WIDTH from current pixel

respond_to_S_horizontal:

# move capsule to the right
respond_to_D:
    lw $t0, 0($a0)      # coordinate 1 in matrix
    lw $t1, 0($a1)      # coordinate 2 in matrix
    lw $t2, HEIGHT      # HEIGHT
    lw $t3, WIDTH       # WIDTH 
    lw $t4, START       # START

respond_to_D_vertical_horizontal:
    addi $t5, $t0, 4    # add 4 from to pixel 1 value
    div $t0, $t2        # divide coordinate 1 by HEIGHT
    mflo $t6            # store quotient (height)

    mult $t6, $t3       # multiply coordinate 1 height and WIDTH to get leftmost address at that height
    mflo $t6            # store leftmost address at that height
    add $t6, $t6, $t3   # go to the rightmost address at that height

    slt $t7, $t5, $t6   # check if resulting capsule coordinate 1 is less than rightmost address at that height
    beq $t7, $zero, finish_keyboard_input   # no space for capsule to go right, return
    
    addi $t8, $t1, 4   # add 4 to capsule 2 value
    
    sw $t5, 0($a0)      # update memory to store updated coordinate 1
    sw $t8, 0($a1)      # update memory to store updated coordinare 2
    
    j finish_keyboard_input
    
# This initializes an array of capsules on the stack, where 4 bytes corresponds to a color and 8 bytes represents a capsule.
# Imaging this as a queue data structure. The first element is the capsule that the player is controlling, the rest are
# the upcommign capsules. Note that stack is "backwards".   
init_capsules:
    # $a2 is the address to store the capsule 
    addi $a2, $sp, -8
    jal generate_capsule  
    addi $a2, $a2, -8
    jal generate_capsule
    addi $a2, $a2, -8
    jal generate_capsule
    addi $a2, $a2, -8
    jal generate_capsule
    addi $a2, $a2, -8
    jal generate_capsule
    addi $a2, $a2, -8
    jal generate_capsule
    j game_loop

# Param: initialize $a2 at stack for location
generate_capsule:
    j which_capsule
    
# decides which capsule to display next
# 0: red-red
# 1: yellow-yellow
# 2: blue-blue
# 3: red-blue
# 4: red-yellow
# 5: blue-yellow
which_capsule:
    # generate random number between 0 and 5 (inclusive) to decide which capsule to display next
    # result stored in $a0
    li $v0 , 42
    li $a0 , 0
    li $a1 , 1
    syscall
    
    # invoke specific colour function based on number generated
    beq $a0, 0, which_capsule_0
    beq $a0, 1, which_capsule_1
    beq $a0, 2, which_capsule_2
    beq $a0, 3, which_capsule_3
    beq $a0, 4, which_capsule_4
    beq $a0, 5, which_capsule_5

which_capsule_0:
    # red-red
    lw $t0, RED
    add $t0, $zero, $t0  # dereference addr for color
    sw $t0, 0($a2)
    sw $t0, 4($a2)
    j draw_capsule # TODO change to jr $ra

which_capsule_1:
    # yellow-yellow
    sw $a2, YELLOW
    addi, $a2, $a2, 4
    sw $a2, YELLOW
    j draw_capsule

which_capsule_2:
    # blue-blue
    sw $a2, BLUE
    addi, $a2, $a2, 4
    sw $a2, BLUE
    j draw_capsule

which_capsule_3:
    # red-blue
    sw $a2, RED
    addi, $a2, $a2, 4
    sw $a2, BLUE
    j draw_capsule

which_capsule_4:
    # red-yellow
    sw $a2, RED
    addi, $a2, $a2, 4
    sw $a2, YELLOW
    j draw_capsule
    
which_capsule_5:
    # blue-yellow
    sw $a2, BLUE
    addi, $a2, $a2, 4
    sw $a2, YELLOW
    j draw_capsule
    
# draws the capsule at the bottle neck 
# TODO the function jumping may be changed later when generation state management is implemented
draw_capsule:
    # lw $t0, CAPSULE_INIT_POS
    # sw $v0, 0($t0)
    # sw $v1, 256($t0)
    jr $ra
    
# t0 represents to the stack address of the capsule
# t1 represents the position on the display to draw the capsule
# t2 is a loop counter
draw_capsule_queue:
    # drawing the capsule
    lw $t3, 0($t0)  # retrieve color from stack
    sw $t3, 0($t1)  # drawing on the display
    lw $t3, 4($t0)
    sw $t3, 256($t1)
    addi $t0, $t0, -8
    
    addi $t1, $t1, 8
    addi $t2, $t2, 1
    bne $t2, 5, draw_capsule_queue
    jr $ra
    