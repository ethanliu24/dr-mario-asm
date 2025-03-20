################# CSC258 Assembly Final Project ###################
# This file contains our implementation of Dr Mario.
#
# Student 1: Ethan Liu, 1010290338
# Student 2: Jai Joshi, 1009881013
#
# We assert that the code submitted here is entirely our own
# creation, and will indicate otherwise when it is not.
#
######################## Bitmap Display Configuration ########################
# - Unit width in pixels:       1
# - Unit height in pixels:      1
# - Display width in pixels:    64
# - Display height in pixels:   32
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


RED:
    .word 0xff0000
BLUE:
    .word 0x0000ff
YELLOW:
    .word 0xffff00
BLACK:
    .word 0x000000
GRAY:
    .word 0x808080

VIRUS_RED:
    .word 0xff7f7f
VIRUS_BLUE:
    .word 0xadd8e6
VIRUS_YELLOW:
    .word 0xffffe0

HEIGHT:
    .word 0x000018
WIDTH:
    .word 0x000011
START:
    .word 0x10008514    # ADDR_DSPL + 5x4 + 5x256

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
    j initialize_game

initialize_game:
    addi $s6, $zero, 1  # s6 repr the game state, 1 is ready state
    addi $s7, $zero, 0  # fps counter
    
    # initialize virus counter 
    addi $s3, $zero, 1
    addi $s4, $zero, 1
    addi $s5, $zero, 1
    
    # repaint the screen
    addi $t0, $zero, 0
    lw $a0, ADDR_DSPL
    addi $a1, $zero, 64
    addi $a2, $zero, 32
    jal reset_area  
    
    j draw_bottle  # will jump to other functions that initializes the game

game_loop:
    # draw the upcomming capsules
    addi $t0, $sp, -16
    lw $t1, CAPSULE_INIT_POS
    addi $t1, $t1, 56
    li $t2, 0  # loop counter
    jal draw_capsule_queue
    
    # 1a. Check if key has been pressed
    # 1b. Check which key has been pressed
    lw $t0, ADDR_KBRD               # $t0 = base address for keyboard
    lw $t8, 0($t0)                  # Load first word from keyboard
    beq $t8, 1, keyboard_input      # If first word 1, key is pressed

    # handle game states
    lw $t1, READY
    beq $s6, $t1, handle_ready_state
    lw $t1, ENTERING
    beq $s6, $t1, handle_entering_state
    


    # after key presses because need to listen to replay key press
    lw $t1, GAME_OVER
    beq $s6, $t1, handle_game_over_state
    
    # falling state
    
    # 60 fps
    li $v0, 32
    li $a0, 16
    syscall  # sleeps for ~1/60s

    # handle fps counter, # s7 == 60 => update capsule position
    addi $s7, $s7, 1
    bne $s7, 60, skip_gravity
    addi $s7, $zero, 0
    j move_down

handle_ready_state:
    lw $t0, CAPSULE_INIT_POS
    addi $t1, $sp, -8  # get a player controlled capsule
    lw $t2, 0($t1)
    sw $t2, 0($t0)
    addi $t1, $t1, 4
    lw $t2, 0($t1)
    sw $t2, 256($t0)

    lw $s6, ENTERING
    j game_loop

handle_entering_state:
    # animation for capsule to move into bottle
    lw $t0, CAPSULE_INIT_POS
    addi $t1, $sp, -8

    li $v0, 32
    li $a0, 1000
    syscall

    lw $t2, BLACK
    sw $t2, 0($t0)
    lw $t2, 0($t1)
    sw $t2, 256($t0)
    lw $t2, 4($t1)
    sw $t2, 512($t0)

    li $v0, 32
    li $a0, 1000
    syscall

    lw $t2, BLACK
    sw $t2, 256($t0)
    lw $t2, 0($t1)
    sw $t2, 512($t0)
    lw $t2, 4($t1)
    sw $t2, 768($t0)

    # stores the addr in matrix
    li $a2, 0
    addi $s0, $t0, 512
    addi $s1, $t0, 768
    addi $s7, $zero, 0  # reset fps counter to avoid sudden changes due to previous fps values
    lw $s6, FALLING
    j game_loop
    
handle_game_over_state:
    j game_loop

skip_gravity:
    j game_loop
    
# reset the given area by setting everything to black
# $t0 is the loop counter
# $a0 is the top left corner of the given area
# $a1 is the width of the area
# $a2 is the height of the area
reset_area:
    addi $t1, $zero, 0  # loop counter for resetting a row
    addi $t2, $a0, 0
    addi $a0, $a0, 256
    addi $t0, $t0, 1
    j reset_row
    
reset_row:
    lw $t3, BLACK
    sw $t3, 0($t2)
    addi $t2, $t2, 4
    addi $t1, $t1, 1
    bne $t1, $a1, reset_row
    j reset_check
    
# checks if the area has finished painting. if not, proceed to the next row.
reset_check:
    bne $t0, $a2, reset_area
    jr $ra

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

    j generate_virus

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
    # generate new capsule when can't move down (i.e. when $v0 == 0)
	beq $v0, 1, game_loop
	
	# complete the top horizontal line to be gray for check pattern
	lw $t0, START
	addi $t0, $t0, -256    # move one row up
	addi $t0, $t0, 28      # 7x4
	
	lw $t1, GRAY
	sw $t1, 0($t0)
	
	addi $t0, $t0, 4
	sw $t1, 0($t0)
	
	addi $t0, $t0, 4
	sw $t1, 0($t0)
	
	beq $v0, 0, check_pattern       # if we can't move down, this means current capsule time is over and we need to check for patterns for deletions
	
check_pattern_return:               # come back to continue executing code after any deletions
    # make the 3 pixels on the horizontal line black again
    lw $t0, START
	addi $t0, $t0, -256    # move one row up
	addi $t0, $t0, 28      # 7x4
	
	lw $t1, BLACK
	sw $t1, 0($t0)
	
	addi $t0, $t0, 4
	sw $t1, 0($t0)
	
	addi $t0, $t0, 4
	sw $t1, 0($t0)
	
	# check if there's still viruses remaining
    bne $s3, $zero, check_space 
    bne $s4, $zero, check_space 
    bne $s5, $zero, check_space 
    
    j declare_game_over
    
# check if spaces are filled up
check_space:
    lw $t0, CAPSULE_INIT_POS
    lw $t1, 512($t0)  # color at the position of the top most row where the capsule initially falls
    lw $t0, BLACK
    bne $t0, $t1, declare_game_over
    
    lw $s6, READY
	jal dequeue_capsule
    j game_loop
    
declare_game_over:
    lw $s6, GAME_OVER
    j game_loop

keyboard_input:                     # A key is pressed
    lw $a0, 4($t0)                  # Load second word from keyboard
    addi $v0, $zero, 1
    beq $a0, 0x71, respond_to_Q     # Check if the key q was pressed
    beq $a0, 0x72, respond_to_R     # Check if the key r was pressed
    beq $a0, 0x77, respond_to_W     # Check if the key w was pressed
    beq $a0, 0x61, respond_to_A     # Check if the key a was pressed
    beq $a0, 0x73, respond_to_S     # Check if the key s was pressed
    beq $a0, 0x64, respond_to_D     # Check if the key d was pressed

    # li $v0, 1                       # ask system to print $a0
    # syscall

    j finish_keyboard_input

respond_to_Q:
    li $v0, 10                      # Quit gracefully
	syscall

	b finish_keyboard_input
	
respond_to_R:
    lw $s6, READY
    j initialize_game

# rotate capsule by 90 degrees clockwise
respond_to_W:
    add $a0, $zero, $s0 # initialize coordinate 1
    add $a1, $zero, $s1 # initialize coordinate 2
    add $a2, $zero, $s2 # initialize number of times rotated

    lw $t0, 0($a0)      # coordinate 1 in matrix
    lw $t1, 0($a1)      # coordinate 2 in matrix
    la $t7, BLACK
    lw $t2, 0($t7)      # BLACK

    beq $a2, 0, respond_to_W_top_to_right       # original state
    beq $a2, 1, respond_to_W_right_to_bottom    # 1 rotation
    beq $a2, 2, respond_to_W_bottom_to_left     # 2 rotations
    beq $a2, 3, respond_to_W_left_to_top        # 3 rotations

respond_to_W_top_to_right:
    lw $t3, 4($a1)      # store colour of right address

    bne $t3, $t2, finish_keyboard_input # if not black, return

    sw $t2, 0($a0)      # make pixel where capsule was black

    sw $t0, 4($a1)      # update memory to store updated coordinate 2

    addi $a0, $a1, 4    # new pixel right/bottom location

    add $s0, $zero, $a1 # new pixel saved in s0
    add $s1, $zero, $a0 # new pixel saved in s1

    j respond_to_W_end

respond_to_W_right_to_bottom:
    lw $t3, 256($a0)    # store colour of bottom address

    bne $t3, $t2, finish_keyboard_input # if not black, return

    sw $t2, 0($a1)      # make pixel where capsule was black

    sw $t1, 256($a0)    # update memory to store updated coordinate 2

    addi $a1, $a0, 256  # new pixel right/bottom location

    add $s0, $zero, $a0 # new pixel saved in s0
    add $s1, $zero, $a1 # new pixel saved in s1

    j respond_to_W_end

respond_to_W_bottom_to_left:
    lw $t3, -4($a0)      # store colour of right address

    bne $t3, $t2, finish_keyboard_input # if not black, return

    sw $t2, 0($a1)      # make pixel where capsule was black

    sw $t1, -4($a0)     # update memory to store updated coordinate 2

    addi $a1, $a0, -4   # new pixel right/bottom location

    add $s0, $zero, $a1 # new pixel saved in s0
    add $s1, $zero, $a0 # new pixel saved in s1

    j respond_to_W_end

respond_to_W_left_to_top:
    lw $t3, -256($a1)   # store colour of bottom address

    bne $t3, $t2, finish_keyboard_input # if not black, return

    sw $t2, 0($a0)      # make pixel where capsule was black

    sw $t0, -256($a1)   # update memory to store updated coordinate 2

    addi $a0, $a1, -256 # new pixel right/bottom location

    add $s0, $zero, $a0 # new pixel saved in s0
    add $s1, $zero, $a1 # new pixel saved in s1

    j respond_to_W_end

respond_to_W_end:
    # update number of rotations
    addi $s2, $s2, 1    # increase number of rotations by 1

    blt $s2, 4, finish_keyboard_input   # if number of new rotations is less than 4, return

    add $s2, $zero, $zero   # make number of rotations 0 again if exceeds 4 (back to original state_

    j finish_keyboard_input


# move capsule to the left
respond_to_A:
    add $a0, $zero, $s0 # initialize coordinate 1
    add $a1, $zero, $s1 # initialize coordinate 2

    lw $t0, 0($a0)      # coordinate 1 in matrix
    lw $t1, 0($a1)      # coordinate 2 in matrix
    la $t7, BLACK
    lw $t2, 0($t7)      # BLACK

respond_to_A_vertical_horizontal:
    lw $t3, -4($a0)      # store colour of left address

    bne $t3, $t2, finish_keyboard_input # if not black, return

    sw $t2, 0($a0)      # make pixel where capsule was black
    sw $t2, 0($a1)      # make pixel where capsule was black

    sw $t0, -4($a0)     # update memory to store updated coordinate 1
    sw $t1, -4($a1)     # update memory to store updated coordinate 2

    addi $a0, $a0, -4  # new pixel left/top location
    addi $a1, $a1, -4  # new pixel right/bottom location

    add $s0, $zero, $a0 # new left/top pixel saved in s0
    add $s1, $zero, $a1 # new right/bottom pixel saved in s1

    j finish_keyboard_input


# move capsule to the right
respond_to_D:
    add $a0, $zero, $s0 # initialize coordinate 1
    add $a1, $zero, $s1 # initialize coordinate 2

    lw $t0, 0($a0)      # coordinate 1 in matrix
    lw $t1, 0($a1)      # coordinate 2 in matrix
    la $t7, BLACK
    lw $t2, 0($t7)      # BLACK

respond_to_D_vertical_horizontal:
    lw $t3, 4($a1)      # store colour of right address

    bne $t3, $t2, finish_keyboard_input # if not black, return

    sw $t2, 0($a0)      # make pixel where capsule was black
    sw $t2, 0($a1)      # make pixel where capsule was black

    sw $t0, 4($a0)     # update memory to store updated coordinate 1
    sw $t1, 4($a1)     # update memory to store updated coordinate 2

    addi $a0, $a0, 4  # new pixel left/top location
    addi $a1, $a1, 4  # new pixel right/bottom location

    add $s0, $zero, $a0 # new left/top pixel saved in s0
    add $s1, $zero, $a1 # new right/bottom pixel saved in s1

    j finish_keyboard_input


# move capsule all the way to the bottom
respond_to_S:
    addi $a2, $zero, 1  # send 1 to move_down in $a2

respond_to_S_while:
    j move_down # will terminate inside move_down


# move down capsule by 1
# returns 1 if successful move down, 0 otherwise
# return value in $v0
move_down:
    add $a0, $zero, $s0 # initialize coordinate 1
    add $a1, $zero, $s1 # initialize coordinate 2

    lw $t0, 0($a0)      # coordinate 1 in matrix
    lw $t1, 0($a1)      # coordinate 2 in matrix
    la $t7, BLACK
    lw $t2, 0($t7)      # BLACK

    addi $t6, $zero, 1  # store 1
    add $t7, $a2 $zero  # check if function called by respond_to_S, 1 if yes, 0 if not

    add $v0, $zero, $zero   # initialize return value of 0

    addi $t3, $a0, 4    # go to next address horizontally
    beq $t3, $a1, move_down_horizontal  # if capsule is horizontal

move_down_vertical:
    lw $t3, 256($a1)    # store colour of bottom address

    bne $t3, $t2, finish_keyboard_input # if not black, return 0

    sw $t2, 0($a0)      # make pixel where capsule was black
    sw $t2, 0($a1)      # make pixel where capsule was black

    sw $t0, 256($a0)    # update memory to store updated coordinate 1
    sw $t1, 256($a1)    # update memory to store updated coordinate 2

    addi $a0, $a0, 256  # new pixel top location
    addi $a1, $a1, 256  # new pixel bottom location

    add $s0, $zero, $a0 # new top pixel saved in s0
    add $s1, $zero, $a1 # new bottom pixel saved in s1

    addi $v0, $zero, 1  # successful move down vertically, return 1

    beq $t6, $t7, respond_to_S_while    # if function called by respond_to_S and we were able to move down, call it again

    j finish_keyboard_input

move_down_horizontal:
    lw $t3, 256($a0)    # store colour of bottom left address
    lw $t4, 256($a1)    # store colour of bottom right address

    bne $t3, $t2, finish_keyboard_input # if not black (bottom left), return 0
    bne $t4, $t2, finish_keyboard_input # if not black (bottom right), return 0

    sw $t2, 0($a0)      # make pixel where capsule was black
    sw $t2, 0($a1)      # make pixel where capsule was black

    sw $t0, 256($a0)    # update memory to store updated coordinate 1
    sw $t1, 256($a1)    # update memory to store updated coordinate 2

    addi $a0, $a0, 256  # new pixel left location
    addi $a1, $a1, 256  # new pixel right location

    add $s0, $zero, $a0 # new left pixel saved in s0
    add $s1, $zero, $a1 # new right pixel saved in s1

    addi $v0, $zero, 1  # successful move down vertically, return 1

    beq $t6, $t7, respond_to_S_while    # if function called by respond_to_S and we were able to move down, call it again

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
    li $a1 , 6
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
    jr $ra
    jr $ra

which_capsule_1:
    # yellow-yellow
    lw $t0, YELLOW
    add $t0, $zero, $t0
    sw $t0, 0($a2)
    sw $t0, 4($a2)
    jr $ra
    lw $t0, YELLOW
    add $t0, $zero, $t0
    sw $t0, 0($a2)
    sw $t0, 4($a2)
    jr $ra

which_capsule_2:
    # blue-blue
    lw $t0, BLUE
    add $t0, $zero, $t0
    sw $t0, 0($a2)
    sw $t0, 4($a2)
    jr $ra
    lw $t0, BLUE
    add $t0, $zero, $t0
    sw $t0, 0($a2)
    sw $t0, 4($a2)
    jr $ra

which_capsule_3:
    # red-blue
    lw $t0, RED
    add $t0, $zero, $t0
    sw $t0, 0($a2)
    lw $t0, BLUE
    add $t0, $zero, $t0
    sw $t0, 4($a2)
    jr $ra
    lw $t0, RED
    add $t0, $zero, $t0
    sw $t0, 0($a2)
    lw $t0, BLUE
    add $t0, $zero, $t0
    sw $t0, 4($a2)
    jr $ra

which_capsule_4:
    # red-yellow
    lw $t0, RED
    add $t0, $zero, $t0
    sw $t0, 0($a2)
    lw $t0, YELLOW
    add $t0, $zero, $t0
    sw $t0, 4($a2)
    jr $ra

which_capsule_5:
    # blue-yellow
    lw $t0, BLUE
    add $t0, $zero, $t0
    sw $t0, 0($a2)
    lw $t0, YELLOW
    add $t0, $zero, $t0
    sw $t0, 4($a2)
    jr $ra

# Intended to be called after the current capsule can't move down anymore.
# It will dequeue the first capsule (the current capsule) and generate another one in the queue.
dequeue_capsule:
    addi $t0, $sp, -16
    addi $t1, $zero, 0
    j shift_queue

# $t0: position of a capsule in the queue
# $t1: loop counter
shift_queue:
    # shift a single capsule
    lw $t2, 0($t0)
    sw $t2, 8($t0)
    lw $t2, 4($t0)
    sw $t2, 12($t0)

    addi $t0, $t0, -8
    addi $t1, $t1, 1
    bne $t1, 5, shift_queue

    # generate a capsule at the last position in the queue
    addi $a2, $sp, -48
    j generate_capsule

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

# generates and displays random viruses across the map
generate_virus:
    addi $t7, $zero, 4      # store 4
    addi $t6, $zero, 256    # store 256
    jal generate_virus_red
    jal generate_virus_blue
    jal generate_virus_yellow
    j init_capsules

generate_virus_red:
    # generate random number between 0 and 17 (exclusive) to decide which column to display virus on
    # result stored in $a0
    li $v0, 42
    li $a0, 0
    li $a1, 17
    syscall

    add $t0, $zero, $a0  # random column
    mult $t0, $t7
    mflo $t0        # multiply by 4 and store result

    # generate random number between 12 and 24 (exclusive)to decide which row to display virus on
    # result stored in $a0
    li $v0, 42
    li $a0, 0
    li $a1, 12
    syscall

    addi $t1, $a0, 12   # random row
    mult $t1, $t6
    mflo $t1            # multiply by 256 and store result

    la $t2, START
    lw $t5, 0($t2)      # store START address
    add $t5, $t5, $t0   # add columns to START
    add $t5, $t5, $t1   # add rows to START + columns, final address to store virus

    la $t2, VIRUS_RED
    lw $t3, 0($t2)      # VIRUS_RED

    sw $t3, 0($t5)      # store VIRUS_RED at virus location
    jr $ra

generate_virus_blue:
    # generate random number between 0 and 17 (exclusive) to decide which column to display virus on
    # result stored in $a0
    li $v0, 42
    li $a0, 0
    li $a1, 17
    syscall

    add $t0, $zero, $a0  # random column
    mult $t0, $t7
    mflo $t0        # multiply by 4 and store result

    # generate random number between 12 and 24 (exclusive)to decide which row to display virus on
    # result stored in $a0
    li $v0, 42
    li $a0, 0
    li $a1, 12
    syscall

    addi $t1, $a0, 12   # random row
    mult $t1, $t6
    mflo $t1            # multiply by 256 and store result

    la $t2, START
    lw $t5, 0($t2)      # store START address
    add $t5, $t5, $t0   # add columns to START
    add $t5, $t5, $t1   # add rows to START + columns, final address to store virus

    la $t2, VIRUS_BLUE
    lw $t3, 0($t2)      # VIRUS_BLUE

    sw $t3, 0($t5)      # store VIRUS_BLUE at virus location
    jr $ra

generate_virus_yellow:
    # generate random number between 0 and 17 (exclusive) to decide which column to display virus on
    # result stored in $a0
    li $v0, 42
    li $a0, 0
    li $a1, 17
    syscall

   add $t0, $zero, $a0  # random column
    mult $t0, $t7
    mflo $t0        # multiply by 4 and store result

    # generate random number between 12 and 24 (exclusive)to decide which row to display virus on
    # result stored in $a0
    li $v0, 42
    li $a0, 0
    li $a1, 12
    syscall

    addi $t1, $a0, 12   # random row
    mult $t1, $t6
    mflo $t1            # multiply by 256 and store result

    la $t2, START
    lw $t5, 0($t2)      # store START address
    add $t5, $t5, $t0   # add columns to START
    add $t5, $t5, $t1   # add rows to START + columns, final address to store virus

    la $t2, VIRUS_YELLOW
    lw $t3, 0($t2)      # VIRUS_YELLOW

    sw $t3, 0($t5)      # store VIRUS_YELLOW at virus location
    jr $ra

# in case of horizontal or vertical matching, remove adjacent blocks
# $t7 - current address, START
# $t6 - GRAY
# $t5 - BLACK
# $t4
# $t3 - count, 1 by default
# $t2 - prev colour, GRAY by default
# $t1
# $t0 - colour at current address
check_pattern:

check_pattern_horizontal:
    lw $t7, START           # START
    addi $t7, $t7, 5888     # 256x23, to go to last row, first column
    
    lw $t6, GRAY            # GRAY
    lw $t5, BLACK           # BLACK

    lw $t2, GRAY    # prev colour, initially GRAY
    li $t3, 1       # count of current colour, initially 1

check_pattern_horizontal_inner_loop:
    lw $t0, 0($t7)                                      # colour at current address
    
    bne $t0, $t2, check_pattern_horizontal_new          # diff colour than prev
    beq $t0, $t5, check_pattern_horizontal_reset        # reset if black pixel
    beq $t0, $t2, check_pattern_horizontal_add          # same colour as prev
    
check_pattern_horizontal_inner_loop_cont:
    beq $t0, $t6, check_pattern_horizontal_outer_loop   # end loop when we reach gray
    addi $t7, $t7, 4                                    # go to next column
    j check_pattern_horizontal_inner_loop

check_pattern_horizontal_outer_loop:
    addi $t7, $t7, -324                         # go to row above, -256 - 4x17
    lw $t0, 0($t7)                              # colour at current address
    beq $t0, $t6, check_pattern_vertical        # end outer loop when we reach gray
    
    # reset prev colour and count since new row
    lw $t2, GRAY
    li $t3, 1
    
    j check_pattern_horizontal_inner_loop

check_pattern_horizontal_reset:
    # reset prev colour and count when we encounter black pixel
    lw $t2, GRAY
    li $t3, 1
    j check_pattern_horizontal_inner_loop_cont


check_pattern_horizontal_new:
    # new pixel colour found, check if >= 4 found for prev
    lw $t4, VIRUS_RED
    beq $t0, $t4, check_pattern_horizontal_new_red_virus        # red virus found
    lw $t4, VIRUS_BLUE
    beq $t0, $t4, check_pattern_horizontal_new_blue_virus       # blue virus found
    lw $t4, VIRUS_YELLOW
    beq $t0, $t4, check_pattern_horizontal_new_yellow_virus     # yellow virus found
    
    j check_pattern_horizontal_new_no_virus                     # no virus
    
check_pattern_horizontal_new_red_virus:
    beq $t3, 1, check_pattern_horizontal_new_red_virus_first    # if first pixel is a virus
    
    lw $t4, RED
    bne $t2, $t4, check_pattern_horizontal_new_no_virus         # prev is not red
    addi $t3, $t3, 1                                            # if prev is red, increment count
    j check_pattern_horizontal_inner_loop_cont                  # continue iteration
    
check_pattern_horizontal_new_red_virus_first:
    lw $t2, RED                                                 # set prev as RED
    j check_pattern_horizontal_inner_loop_cont                  # continue iteration

check_pattern_horizontal_new_blue_virus:
    beq $t3, 1, check_pattern_horizontal_new_blue_virus_first   # if first pixel is a virus
    
    lw $t4, BLUE
    bne $t2, $t4, check_pattern_horizontal_new_no_virus         # prev is not blue
    addi $t3, $t3, 1                                            # if prev is blue, increment count
    j check_pattern_horizontal_inner_loop_cont                  # continue iteration
    
check_pattern_horizontal_new_blue_virus_first:
    lw $t2, BLUE                                                # set prev as BLUE
    j check_pattern_horizontal_inner_loop_cont                  # continue iteration
    
check_pattern_horizontal_new_yellow_virus:
    beq $t3, 1, check_pattern_horizontal_new_yellow_virus_first # if first pixel is a virus
    
    lw $t4, YELLOW
    bne $t2, $t4, check_pattern_horizontal_new_no_virus         # prev is not yellow
    addi $t3, $t3, 1                                            # if prev is yellow, increment count
    j check_pattern_horizontal_inner_loop_cont                  # continue iteration
    
check_pattern_horizontal_new_yellow_virus_first:
    lw $t2, YELLOW                                              # set prev as YELLOW
    j check_pattern_horizontal_inner_loop_cont                  # continue iteration
    
check_pattern_horizontal_new_no_virus:
    bgt $t3, 3, check_pattern_horizontal_found                  # if prev count >3, we found a row patterm
    
    add $t2, $zero, $t0                                         # store colour of new pixel
    li $t3, 1                                                   # reset count to 1
    j check_pattern_horizontal_inner_loop_cont                  # continue iteration prev count <=3


check_pattern_horizontal_found:
    # row pattern found, make all pixels black, call ethan_delete, with address of topmost pixel in $a0
    li $t4, 4
    mul $t4, $t4, $t3       # 4 x number of pixels found 
    
    sub $t1, $t7, $t4       # go back to start of row pattern
    
check_pattern_horizontal_found_loop:
    beq $t1, $t7, check_pattern         # when we finish deleting current row and pushing the respective columns down, we want to call check_pattern again
    
    lw $a1, VIRUS_RED
    beq $a1, $t0, check_pattern_horizontal_found_loop_red_virus     # if current pixel is the virus
    
    lw $a1, VIRUS_BLUE
    beq $a1, $t0, check_pattern_horizontal_found_loop_blue_virus    # if current pixel is the virus
    
    lw $a1, VIRUS_YELLOW
    beq $a1, $t0, check_pattern_horizontal_found_loop_yellow_virus  # if current pixel is the virus
    
    j check_pattern_horizontal_found_loop_cont                      # no virus

check_pattern_horizontal_found_loop_red_virus:
    li $s3, 0                                                       # red pixel dead
    j check_pattern_horizontal_found_loop_cont

check_pattern_horizontal_found_loop_blue_virus:
    li $s4, 0                                                       # blue pixel dead
    j check_pattern_horizontal_found_loop_cont
    
check_pattern_horizontal_found_loop_yellow_virus:
    li $s5, 0                                                       # yellow pixel dead
    j check_pattern_horizontal_found_loop_cont
    
check_pattern_horizontal_found_loop_cont:
    add $a0, $zero, $t1         # store current pixel memory address as first parameter
    sw $t5, 0($a0)              # make current row pattern pixel black
    
    jal shift_column_down       # shift column down
    
    addi $t1, $t1, 4            # go to next pixel in row
    
    j check_pattern_horizontal_found_loop


check_pattern_horizontal_add:
    addi $t3, $t3, 1        # increment number of occurences
    j check_pattern_horizontal_inner_loop_cont


# ----------------------------------------------------------------------------------------------------------------- vertical pattern check
# $t7 - current address, START
# $t6 - GRAY
# $t5 - BLACK
# $t4
# $t3 - count, 1 by default
# $t2 - prev colour, GRAY by default
# $t1
# $t0 - colour at current address
check_pattern_vertical:
    lw $t7, START           # START
    addi $t7, $t7, 5888     # 256x23, to go to last row, first column
    
    lw $t6, GRAY            # GRAY
    lw $t5, BLACK           # BLACK

    lw $t2, GRAY            # prev colour, initially GRAY
    li $t3, 1               # count of current colour, initially 1

check_pattern_vertical_inner_loop:
    lw $t0, 0($t7)                                      # colour at current address
    
    bne $t0, $t2, check_pattern_vertical_new            # diff colour than prev
    beq $t0, $t5, check_pattern_vertical_reset          # reset if black pixel
    beq $t0, $t2, check_pattern_vertical_add            # same colour as prev
    
check_pattern_vertical_inner_loop_cont:
    beq $t0, $t6, check_pattern_vertical_outer_loop     # end loop when we reach gray
    addi $t7, $t7, -256                                 # go to upper row, same column
    j check_pattern_vertical_inner_loop

check_pattern_vertical_outer_loop:
    addi $t7, $t7, 6148                         # go to next column, 4 + 256x24
    lw $t0, 0($t7)                              # colour at current address
    beq $t0, $t6, check_pattern_return          # return back to executing game code
    
    # reset prev colour and count since new row
    lw $t2, GRAY
    li $t3, 1
    
    j check_pattern_vertical_inner_loop

check_pattern_vertical_reset:
    # reset prev colour and count when we encounter black pixel
    lw $t2, GRAY
    li $t3, 1
    j check_pattern_vertical_inner_loop_cont


check_pattern_vertical_new:
    # new pixel colour found, check if >= 4 found for prev
    lw $t4, VIRUS_RED
    beq $t0, $t4, check_pattern_vertical_new_red_virus          # red virus found
    lw $t4, VIRUS_BLUE
    beq $t0, $t4, check_pattern_vertical_new_blue_virus         # blue virus found
    lw $t4, VIRUS_YELLOW
    beq $t0, $t4, check_pattern_vertical_new_yellow_virus       # yellow virus found
    
    j check_pattern_vertical_new_no_virus                       # no virus
    
check_pattern_vertical_new_red_virus:
    beq $t3, 1, check_pattern_vertical_new_red_virus_first      # if first pixel is a virus
    
    lw $t4, RED
    bne $t2, $t4, check_pattern_vertical_new_no_virus           # prev is not red
    addi $t3, $t3, 1                                            # if prev is red, increment count
    j check_pattern_vertical_inner_loop_cont                    # continue iteration
    
check_pattern_vertical_new_red_virus_first:
    lw $t2, RED                                                 # set prev as RED
    j check_pattern_vertical_inner_loop_cont                    # continue iteration

check_pattern_vertical_new_blue_virus:
    beq $t3, 1, check_pattern_vertical_new_blue_virus_first     # if first pixel is a virus
    
    lw $t4, BLUE
    bne $t2, $t4, check_pattern_vertical_new_no_virus           # prev is not blue
    addi $t3, $t3, 1                                            # if prev is blue, increment count
    j check_pattern_vertical_inner_loop_cont                    # continue iteration
    
check_pattern_vertical_new_blue_virus_first:
    lw $t2, BLUE                                                # set prev as BLUE
    j check_pattern_vertical_inner_loop_cont                    # continue iteration
    
check_pattern_vertical_new_yellow_virus:
    beq $t3, 1, check_pattern_vertical_new_yellow_virus_first   # if first pixel is a virus
    
    lw $t4, YELLOW
    bne $t2, $t4, check_pattern_vertical_new_no_virus           # prev is not yellow
    addi $t3, $t3, 1                                            # if prev is yellow, increment count
    j check_pattern_vertical_inner_loop_cont                    # continue iteration
    
check_pattern_vertical_new_yellow_virus_first:
    lw $t2, YELLOW                                              # set prev as YELLOW
    j check_pattern_vertical_inner_loop_cont                    # continue iteration
    
check_pattern_vertical_new_no_virus:
    bgt $t3, 3, check_pattern_vertical_found                    # if prev count >3, we found a row patterm
    
    add $t2, $zero, $t0                                         # store colour of new pixel
    li $t3, 1                                                   # reset count to 1
    j check_pattern_vertical_inner_loop_cont                    # continue iteration prev count <=3


check_pattern_vertical_found:
    # row pattern found, make all pixels black, call shift_column_down, with address of topmost pixel in $a0
    li $t4, 256
    mul $t4, $t4, $t3       # 256 x number of pixels found
    
    add $t1, $t7, $t4       # go back to start of column pattern
    
check_pattern_vertical_found_loop:
    beq $t1, $t7, check_pattern_vertical_call_shift_down     # when we finish deleting current column and pushing the respective columns down, we want to call check_pattern again

    lw $a1, VIRUS_RED
    beq $a1, $t0, check_pattern_vertical_found_loop_red_virus       # if current pixel is the virus
    
    lw $a1, VIRUS_BLUE
    beq $a1, $t0, check_pattern_vertical_found_loop_blue_virus      # if current pixel is the virus
    
    lw $a1, VIRUS_YELLOW
    beq $a1, $t0, check_pattern_vertical_found_loop_yellow_virus    # if current pixel is the virus
    
    j check_pattern_vertical_found_loop_cont                        # no virus

check_pattern_vertical_found_loop_red_virus:
    li $s3, 0                                                       # red pixel dead
    j check_pattern_vertical_found_loop_cont

check_pattern_vertical_found_loop_blue_virus:
    li $s4, 0                                                       # blue pixel dead
    j check_pattern_vertical_found_loop_cont
    
check_pattern_vertical_found_loop_yellow_virus:
    li $s5, 0                                                       # yellow pixel dead
    j check_pattern_vertical_found_loop_cont
    
check_pattern_vertical_found_loop_cont:
    sw $t5, 0($t1)              # make current row pattern pixel black
    addi $t1, $t1, -256         # go to next pixel in column
    j check_pattern_vertical_found_loop    

check_pattern_vertical_call_shift_down:
    add $a0, $zero, $t1         # store current pixel memory address as first parameter
    jal shift_column_down       # shift all pixels above down
    j check_pattern
    
check_pattern_vertical_add:
    addi $t3, $t3, 1        # increment number of occurences
    j check_pattern_vertical_inner_loop_cont
    
# a0: The addr position of where the highest pixel that was deleted on that row. Shifting what's above.
shift_column_down:
    addi $a0, $a0, -256
    
    # TODO change t registers if needed
    add $a1, $a0, $zero  # the addr of the current pixel to potentially be shifted down
    lw $a2, 0($a0)  # color of the current pixel
    
    # $a3 is the color to be checked
    lw $a3, RED  
    beq $a2, $a3, shift_pixel
    lw $a3, BLUE
    beq $a2, $a3, shift_pixel
    lw $a3, YELLOW
    beq $a2, $a3, shift_pixel
    
    #else: we are on an empty space, border, or virus. We can exit out of the function.
    jr $ra
    
# a1: The address of the pixel processed
# a2: color of the pixel processed
shift_pixel:
    lw $a3, BLACK
    lw $v1, 256($a1)  # color of the pixel below
    
    # if not black, process the next pixel above the current one. Else shift down.
    bne $v1, $a3, shift_column_down
    sw $a3, 0($a1)  # erase current pixel
    addi $a1, $a1, 256
    sw $a2, 0($a1)  # draw pixel on the pixel below
    j shift_pixel