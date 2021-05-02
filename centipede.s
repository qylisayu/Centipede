##################################################################### 
#
# CSC258H Winter 2021 Assembly Final Project 
# University of Toronto, St. George 
# 
# Student: Lisa Yu, 1005786366
# 
# Bitmap Display Configuration: 
# - Unit width in pixels: 8    
# - Unit height in pixels: 8 
# - Display width in pixels: 256 
# - Display height in pixels: 256 
# - Base Address for Display: 0x10008000 ($gp) 
# 
# Milestones reached: 1, 2, 3
# 
# Additional features: N/A
##################################################################### 


.data
	displayAddress:	.word 0x10008000
	bugLocation: .word 1008
	centipedeLocation: .word 0, 1, 2, 3, 4, 5, 6, 7, 8, 9
	centipedeDirection: .word 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
	centipedeHead: .word 0, 0, 0, 0, 0, 0, 0, 0, 0, 1
	mushroomLocation: .word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,0,0,0,0,0,0,0,0,0,0
	dartLocation: .word 0
	dartActive: .word 0
	fleaLocation: .word 1024
	centipede_lifes: .word  3
	
	
.text 

Display_initial_mushrooms:
	addi $a3, $zero, 10	 	# load $a3 with the loop count (10)
	la $t6, mushroomLocation 	# load the address of the array into $t6
	
arr_loop0:			 	# iterate over the loops elements to draw each mushroom
	lw $t1, 0($t6)			# load a word from the mushroomLocation array into $t1
	li $v0, 42			# randomly generate location of mushroom and store in $a0
	li $a0, 0
	li $a1, 900
	syscall
	
	addi $a0, $a0, 11	 	# ensures generated mushroom is not on centipede
	
	lw $t2, displayAddress  	# $t2 stores the base address for display	
	li $t3, 0x00ff00		# $t3 stores the green colour code
	
	sw $a0, 0($t6)			# save the mushroom location
	sll $a0,$a0, 2			
	add $t4, $t2, $a0		# $t4 is the address of the location
	sw $t3, 0($t4)			# paint the mushroom with green
	addi $t6, $t6, 4	 	# increment $t6 by one, to point to the next element in the array
	addi $a3, $a3, -1	 	# decrement $a3 by 1
	bne $a3, $zero, arr_loop0


Loop:					# main loop 
	jal disp_centipede		
	jal disp_mushrooms 
	jal disp_bug
	jal move_flea
	jal disp_flea
	jal check_keystroke
	jal move_dart
	jal disp_dart
	jal check_collision_dart
	jal check_collision_flea
	jal sleep
	jal move_centipede
	j Loop

Exit:
	li $v0, 10		# terminate the program gracefully
	syscall
	
disp_centipede:			# function to display a static centipede
	addi $sp, $sp, -4	# move stack pointer,push ra onto it
	sw $ra, 0($sp)
	
	addi $a3, $zero, 9	 # load $a3 with the loop count (9)
	la $a1, centipedeLocation # load the address of the array into $a1

arr_loop:			#iterate over the loops elements to draw each body in the centipede
	lw $t1, 0($a1)		
	lw $t2, displayAddress  
	li $t3, 0xff0000	# $t3 stores the red colour code
	
	sll $t4,$t1, 2		
	add $t4, $t2, $t4	# $t4 is the address of the location
	sw $t3, 0($t4)		# paint the body with red
	
	
	addi $a1, $a1, 4	 # point to the next element in the array
	addi $a3, $a3, -1	 # decrement $a3 by 1
	bne $a3, $zero, arr_loop

disp_centipede_head:		# display centipede head
	lw $t1, 0($a1)		 # load centipedeLocation into $t1
	lw $t2, displayAddress  
	li $t3, 0xffa9ba	# $t3 stores the pink colour code
	
	sll $t4,$t1, 2		
	add $t4, $t2, $t4	
	sw $t3, 0($t4)		# paint
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra

check_keystroke:    # function to detect any keystroke
	# move stack pointer a word and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	lw $t8, 0xffff0000
	beq $t8, 1, get_keyboard_input # if key is pressed, jump to get this key
	addi $t8, $zero, 0
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
	
# function to get the input key
get_keyboard_input:
	# move stack pointer a word and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	lw $t2, 0xffff0004
	addi $v0, $zero, 0	
	beq $t2, 0x6A, respond_to_j
	beq $t2, 0x6B, respond_to_k
	beq $t2, 0x78, respond_to_x
	beq $t2, 0x73, respond_to_s
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
	
# Call back function of j key
respond_to_j:
	# move stack pointer a word and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	la $t0, bugLocation	# load the address of buglocation from memory
	lw $t1, 0($t0)		# load the bug location itself in t1
	
	lw $t2, displayAddress  # $t2 stores the base address for display
	li $t3, 0x000000	# $t3 stores the black colour code
	
	sll $t4,$t1, 2		
	add $t4, $t2, $t4	# $t4 is the address of the old bug location
	sw $t3, 0($t4)		# paint old location black
	
	beq $t1, 992, skip_movement # prevent the bug from getting out of the canvas
	addi $t1, $t1, -1	# move the bug one location to the right

skip_movement:
	sw $t1, 0($t0)		# save the bug location

	li $t3, 0xffffff	# $t3 stores the white colour code
	
	sll $t4,$t1, 2
	add $t4, $t2, $t4
	sw $t3, 0($t4)		# paint unit white.
	
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra

# Call back function of k key
respond_to_k:
	# move stack pointer a word and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	la $t0, bugLocation	# load the address of buglocation from memory
	lw $t1, 0($t0)		# load the bug location itself in t1
	
	lw $t2, displayAddress  # $t2 stores the base address for display
	li $t3, 0x000000	# $t3 stores the black colour code
	
	sll $t4,$t1, 2		
	add $t4, $t2, $t4	# $t4 is the address of the old bug location
	sw $t3, 0($t4)		# paint the block with black
	
	beq $t1, 1023, skip_movement2 #prevent the bug from getting out of the canvas
	addi $t1, $t1, 1	# move the bug one location to the right
skip_movement2:
	sw $t1, 0($t0)		# save the bug location
	
	li $t3, 0xffffff	# $t3 stores the white colour code
	
	sll $t4,$t1, 2
	add $t4, $t2, $t4
	sw $t3, 0($t4)		# paint the block with white
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
	
respond_to_x:
	# move stack pointer a word and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	la $t7, dartLocation	# load the address of location from memory
	lw $t6, 0($t7)	        # load value of location to $t6
	
	li $t3, 0x000000	# black
	lw $a2, displayAddress
	sll $t5,$t6, 2		# shift
	add $t5, $a2, $t5	
	sw $t3, 0($t5)		# paint
	
	la $t0, bugLocation	# load the address of buglocation from memory
	lw $t1, 0($t0)	        # load value of buglocation to $t1
	la $t2, dartLocation	
	sw $t1, 0($t2)
	
	la $t0, dartActive
	li $t2, 1		# if dart is  active, set dart location to bug location
	sw $t2, 0($t0)
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
	
respond_to_s: 		# restart
	li $a3, 1024	 # load a3 with the loop count

loop_clear_screen:		# reset screen (paint all black)
	la $a1, displayAddress 	# load the address of the array into $a1
	lw $a2, 0($a1)
	li $t3, 0x000000	# black
	addi $t2, $a3, -1
	sll $t5,$t2, 2		
	add $t1, $t5, $a2
	sw $t3, 0($t1)

	addi $a3, $a3, -1	 # decrement $a3 by 1
	bne $a3, $zero, loop_clear_screen
	
	la $a1, bugLocation 	# reset bug location
	li $a3, 1008
	sw $a3, 0($a1)
	
	li $a3, 0
	la $a1, centipedeLocation
clear_centi_loop:		# reset centipede location
	sw $a3, 0($a1)
	
	li $a0, 10
	addi $a1, $a1, 4	 
	addi $a3, $a3, 1	 
	bne $a3, $a0, clear_centi_loop
	
	li $a3, 10
	la $a1, centipedeDirection
clear_centi__direction_loop:	# reset sentipede direction
	li $a2, 1
	sw $a2, 0($a1)
	
	addi $a1, $a1, 4	 
	addi $a3, $a3, -1	 
	bne $a3, $zero, clear_centi__direction_loop
	
	la $a1, dartLocation 	# reset dart location
	li $a3, 0
	sw $a3, 0($a1)
	
	la $a1, dartActive	# set  dart as inactive
	li $a3, 0
	sw $a3, 0($a1)
	
	la $a1, fleaLocation  	# reset flea location
	li $a3, 1024
	sw $a3, 0($a1)
	
	la $a1, centipede_lifes # reset to 3
	li $a3, 3
	sw $a3, 0($a1)
	
	j Display_initial_mushrooms
	

delay:
	# move stack pointer a word and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	li $a2, 50
	addi $a2, $a2, -1
	bgtz $a2, delay
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra

move_centipede:
	# move stack pointer a word and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	addi $a3, $zero, 10	 # load a3 with the loop count (10)
	la $a1, centipedeLocation # load the address
	la $a2, centipedeDirection 
	la $s0, centipedeHead
	
	lw $t1, 0($a1)
	li $t3, 0x000000
	lw $t2, displayAddress  # $t2 stores the base address for display
	
	sll $t4,$t1, 2		
	add $t4, $t2, $t4	# $t4 is the address of location
	sw $t3, 0($t4)
	
arr_loop1:	# checks for when turning
	lw $t1, 0($a1)		 
	lw $t7, 0($a2)
	li $t3, 32
	div $t1, $t3	# check location mod 32
	mfhi $t3
	beq $t3, 31, turn_left #turn left
	beq $t3, 0, turn_right #turn right
	jal continue
	
turn_left:
	beq $t7, -1, continue	# if just turned, then continue
	li $s3, -1		# otherwise change direction
	sw $s3, 0($a2)
	bge $t1, 960, game_over	# if at bottom row, then game over
	addi $s4, $t1, 32	# lower one row
	sw $s4, 0($a1)		# store location
	
	addi $a1, $a1, 4	 # increment $a1 by one, to point to the next element in the array
	addi $a2, $a2, 4
	addi $a3, $a3, -1	 # decrement $a3 by 1
	bne $a3, $zero, arr_loop1
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
	
evade_left: 			# this function is for when centipede is at bottom row (continue evading) (currently not used)
	beq $t7, -1, continue
	li $s3, -1
	sw $s3, 0($a2)
	
	addi $a1, $a1, 4	 # increment $a1 by one, to point to the next element in the array
	addi $a2, $a2, 4
	addi $a3, $a3, -1	 # decrement $a3 by 1
	bne $a3, $zero, arr_loop1 
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
	
turn_right: 
	beq  $t7, 1, continue
	li $s0, 1
	sw $s0, 0($a2)
	bge $t1, 960, game_over
	addi $s4, $t1, 32
	sw $s4, 0($a1)
	
	addi $a1, $a1, 4	 # increment $a1 by one, to point to the next element in the array
	addi $a2, $a2, 4
	addi $a3, $a3, -1	 # decrement $a3 by 1
	bne $a3, $zero, arr_loop1
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
	
evade_right: # this function is for when centipede is at bottom row (continue evading) (currently not used)
	beq  $t7, 1, continue
	li $s0, 1
	sw $s0, 0($a2)
	
	addi $a1, $a1, 4	 # increment $a1 by one, to point to the next element in the array
	addi $a2, $a2, 4
	addi $a3, $a3, -1	 # decrement $a3 by 1
	bne $a3, $zero, arr_loop1
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
	
continue: # continue moving
	add $t5, $t1, $t7
	
	addi $s7, $zero, 20
	la $s5 mushroomLocation
	
loop3: # loops to check for collision with all mushrooms
	lw $t6, 0($s5)
	beq $t6, $t5, collide_mushroom # collision
	addi $s5, $s5, 4
	addi $s7, $s7, -1
	bne $s7, $zero, loop3

	sw  $t5, 0($a1)
	
	addi $a1, $a1, 4	 # increment $a1 by one, to point to the next element in the array
	addi $a2, $a2, 4
	addi $a3, $a3, -1	 # decrement $a3 by 1
	bne $a3, $zero, arr_loop1
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
	
collide_mushroom:
	beq $t7, 1, turn_left
	beq $t7, -1, turn_right
	
sleep: # this is the function we used in main loop
	# move stack pointer a work and push ra onto it 
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	li $v0, 32
	li $a0, 50
	syscall
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
	
move_dart:
	# move stack pointer a work and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	la $t0, dartLocation	
	lw $t1, 0($t0)	        
	
	li $t3, 0x000000
	lw $t2, displayAddress
	addi $t4, $t1, -32
	bge  $t1, 0, changeLocation # continue to move up as long as > 0 location
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
	
changeLocation:
	sw $t4, 0($t0)		#updates location
	
	sll $t5,$t1, 2		
	add $t5, $t2, $t5	
	sw $t3, 0($t5)		# paints previous location black
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
	
disp_dart: 	# paint new dart
	# move stack pointer a word and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	la $a1, dartActive
	lw $a2, 0($a1)
	
	beq $a2, 0, skip	# skip is dart is not active
	
	la $t0, dartLocation	# load the address of buglocation from memory
	lw $t1, 0($t0)	        # load value of location to $t1
	
	li $t3, 0x0000ff	# blue
	lw $t2, displayAddress
	
	sll $t5,$t1, 2		
	add $t5, $t2, $t5	
	sw $t3, 0($t5)		# paint new dart location
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
skip:
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
	
disp_mushrooms: # display mushrooms
	# move stack pointer a word and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	addi $a3, $zero, 10	 # load a3 with the loop count (10) (only 10 to display)
	la $t6, mushroomLocation
	
loop4:	#iterate over the loops elements to draw each mushroom
	lw $t1, 0($t6)		 # load a word from the mushroomLocation array into $t1
	
	lw $t2, displayAddress  # $t2 stores the base address for display	
	li $t3, 0x00ff00	# $t3 stores the green colour code
	
	sll $t1,$t1, 2		
	add $t4, $t2, $t1	
	sw $t3, 0($t4)		# paint the mushroom with green
	addi $t6, $t6, 4	 # increment $t6 to point to the next element in the array
	addi $a3, $a3, -1	 # decrement loop by 1
	bne $a3, $zero, loop4

	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
	
disp_bug: # display bug
	# move stack pointer a work and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	la $t6, bugLocation
	lw $t1, 0($t6)
	lw $t2, displayAddress
	li $t3, 0xffffff	# white
	sll $t1,$t1, 2
	add $t4, $t2, $t1
	sw $t3, 0($t4)		# paint
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
	
disp_flea: # display flea
	# move stack pointer a work and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	la $t6, fleaLocation 
	lw $t1, 0($t6)
	
	bge $t1, 1024, generate_flea # if drop to bottow row, then  re-generate flea at top
	
	li $t3, 0xE533FF # purple
	lw $t2, displayAddress
	
	sll $t5,$t1, 2		
	add $t5, $t2, $t5	
	sw $t3, 0($t5) # paint
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
		
generate_flea:  # generate random flea movements
	# move stack pointer a work and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)

	la $t6, fleaLocation 
	lw $t1, 0($t6)		 

	li $v0, 42	# random number generation range = 31, store in $a0
	li $a0, 0
	li $a1, 31
	syscall
	
	lw $t2, displayAddress  
	li $t3, 0xE533FF	# purple
	
	sw $a0, 0($t6)		# store location
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra

move_flea:
	# move stack pointer a word and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	la $t0, fleaLocation	
	lw $t1, 0($t0)	        
	
	li $t3, 0x000000 #black
	lw $t2, displayAddress
	addi $t4, $t1, 32
	ble  $t1, 1024, changeLocation # move if not at bottom
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
	
check_collision_dart: # check if dart hits centipede
	# move stack pointer a work and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	la $t0, dartLocation	
	lw $t7, 0($t0)	        

	li $a3, 10	 # load a3 with the loop count (10)
	la $a1, centipedeLocation 
	
life_loop: # loops through all segments of centi
	lw $t1, 0($a1)		 
	beq $t1, $t7, minus_life # hit
	addi $a1, $a1, 4	 
	addi $a3, $a3, -1	 
	bne $a3, $zero, life_loop
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra

minus_life:
	# move stack pointer a work and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	la $t0, dartActive	# de-activate dart
	li $t7, 0
	sw $t7, 0($t0)	        
	
	
	la $t0 centipede_lifes
	lw $t1, 0($t0)
	
	add $t1, $t1, -1
	sw $t1, 0($t0)		# decreases centipede life by 1
	
	beq $t1, 0, game_over 	# if life = 0, game over
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra

check_collision_flea: # check if flea hits bug
	# move stack pointer a work and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	la $t0, fleaLocation	
	lw $t7, 0($t0)	        

	la $a1, bugLocation 
	lw $t6, 0($a1)
	beq $t6, $t7, game_over # hits, game over
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
	
game_over:
	j loop_s
loop_s:
	lw $t2, 0xffff0004 	#  user input
	addi $v0, $zero, 0	
	beq $t2, 0x73, respond_to_s # resart if user inputs s
	j loop_s
	
