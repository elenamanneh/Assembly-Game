
#####################################################################
#
# CSCB58 Winter 2024 Assembly Final Project
# University of Toronto, Scarborough
#
# Student: Elena Manneh, 1008171069, mannehe2, elena.manneh@mail.utoronto.ca
#
# Bitmap Display Configuration:
# - Unit width in pixels: 8
# - Unit height in pixels: 8
# - Display width in pixels: 512
# - Display height in pixels: 512
# - Base Address for Display: 0x10008000 ($gp)
#
# Which milestoneshave been reached in this submission?
# - Milestone 1: 	a) Level has more than 3 platforms. 
# 			b) Has a character. 
#			c) 3 additional objects: ghost, stars, door
#
# - Milestone 2:	a) Player can move left, right, and up. 
#			b) Player can't jump when platform is above them, player can land on platform, and there is gravity for jumping. 
#			c) There is vertical movement with jumping. 
# 			d) Collision with ghost ends in a loss. Collision with door when green ends with a win. Collision with all 3 stars 
#			   enables door to be open/green. Regular collision with platforms. 
#			e) r to restart, q to quit.
#
# Which approved features have been implemented for milestone 3?
# 			a) Score is based on stars, get 3 stars you can grab then door opens and you can get the win. There is only 1 life. 
#			b) Fail condition happens when ghost collides with person denoted with a red screen. 
#			c) Win condition if the players grabs 3 stars and enters the green door.
#
# - Milestone 4: 	a) Different modes/levels; normal mode and ghost mode.
#			b) Moving object. Ghost is always moving in ghost mode.
#			c) Start screen only shows the platforms. Press g for ghost mode and n for normal mode.
#
# Link to video demonstration for final submission:
# - https://youtu.be/ZYj1E6huLnU
#
# Are you OK with us sharing the video with people outside course staff?
# - yes
# - https://github.com/elenamanneh/Escape-the-Ghost (will be made public later)
#
#####################################################################


# Display
.eqv BASE_ADDRESS 0x10008000
.eqv screenWidth 64
.eqv screenHeight 64
.eqv sleepDuration 40

# Input 
.eqv keyW 119
.eqv keyA 97
.eqv keyS 115
.eqv keyD 100
.eqv keyR 114
.eqv keyQ 113
.eqv keyG 103
.eqv keyN 110
.eqv keyS 115

.eqv GRAV_ACCEL 1

.data

# Player
colorPlayer: .word 0x000000
playerWidth: .word 5
playerHeight: .word 10
playerStartX: .word 20
playerStartY: .word 51
playerVerticalVelocity: .word 6
playerHorizentalVelocity: .word 6

# Ghost
colorGhost: .word 0x000000
ghostWidth: .word 12
ghostHeight: .word 12
ghostStartX: .word 0
ghostStartY: .word 50
ghostHorizentalVelocity: .word 1
ghostDirection: .word 1 

# Level Objects
colorBackground: .word 0xffffff
colorPlatform: .word 0x000000
platform0: .word 0, -2, 64
platform1: .word 0, 15, 12
platform2: .word 23, 15, 10
platform3: .word 45, 15, 6
platform4: .word 17, 31, 8
platform5: .word 41, 31, 22
platform6: .word 0, 47, 16
platform7: .word 33, 47, 16
platform8: .word 0, 62, 64
colorStar: .word 0xfcf003
colorStarOutline: .word 0xfcba03
star1: .word 24, 4
star2: .word 3, 27
star3: .word 52, 51
colorDoorClosed: .word 0xff0000
colorDoorOpen: .word 0x00Ff00

###################################################
#               BASE GAME STRUCTURE
###################################################

.text
.globl main

main:

lw $s0, playerStartX	
lw $s1, playerStartY		
li $s2, 0 		
lw $s3, ghostStartX
lw $s4, ghostStartY
li $s5, 1
li $s6, 1 
li $s7, 1 

WELCOME:
	jal CLEAR_SCREEN
	jal DRAW_PLATFORMS
	LOOP:
	jal CHECK_INPUT
	j LOOP

END:
	jal CLEAR_SCREEN
	li $v0, 10
	syscall
	
LOSE:
	jal LOSE_SCREEN
	jal CHECK_INPUT
	j LOSE
	
WIN:
	jal WIN_SCREEN
	jal CHECK_INPUT
	j WIN
	
DRAW_LEVEL_NOGHOST:

	jal CLEAR_SCREEN
	jal DRAW_PLATFORMS
	
GAME_LOOP_NOGHOST:
	jal DRAW_DOOR
	jal DOOR_COLLISION
	jal CHECK_INPUTG
	jal CHECK_STARS_COLLISIONG
	jal DRAW_STAR1
	jal DRAW_STAR2
	jal DRAW_STAR3
	jal CHECK_GROUNDEDG     
	jal UPDATE_LOCATIONG
	li $v0, 32
  	li $a0, sleepDuration
    	syscall
	j GAME_LOOP_NOGHOST

DRAW_LEVEL:
	jal CLEAR_SCREEN
	jal DRAW_PLATFORMS
GAME_LOOP:
	jal DRAW_DOOR
	jal DOOR_COLLISION
	jal CHECK_INPUT
	jal CHECK_STARS_COLLISION
	jal CHECK_GHOST_COLLISION
	jal DRAW_STAR1
	jal DRAW_STAR2
	jal DRAW_STAR3
	jal UPDATE_GHOST_LOCATION
	jal CHECK_GROUNDED       
	jal UPDATE_LOCATION
	li $v0, 32
  	li $a0, sleepDuration
    	syscall
	j GAME_LOOP

###################################################
#                     DRAWING    
###################################################

CLEAR_SCREEN:
	li $t0, BASE_ADDRESS
	li $t1, screenWidth
	lw $t2, colorBackground
	li $t3, 4
	mult $t1, $t1
	mflo $t1
	mult $t1, $t3
	mflo $t1
	add $t1, $t0, $t1
	CLEAR_SCREEN_LOOP:
		bgt $t0, $t1, DONE_CLEAR_SCREEN
		sw $t2, 0($t0)
		addi $t0, $t0, 4
		j CLEAR_SCREEN_LOOP
	DONE_CLEAR_SCREEN:
		jr $ra
		
LOSE_SCREEN:
	li $t0, BASE_ADDRESS
	li $t1, screenWidth
	lw $t2, colorDoorClosed
	li $t3, 4
	mult $t1, $t1
	mflo $t1
	mult $t1, $t3
	mflo $t1
	add $t1, $t0, $t1
	LOSE_SCREEN_LOOP:
		bgt $t0, $t1, DONE_LOSE_SCREEN
		sw $t2, 0($t0)
		addi $t0, $t0, 4
		j LOSE_SCREEN_LOOP
	DONE_LOSE_SCREEN:
		jr $ra
		
WIN_SCREEN:
	li $t0, BASE_ADDRESS
	li $t1, screenWidth
	lw $t2, colorDoorOpen
	li $t3, 4
	mult $t1, $t1
	mflo $t1
	mult $t1, $t3
	mflo $t1
	add $t1, $t0, $t1
	WIN_SCREEN_LOOP:
		bgt $t0, $t1, DONE_WIN_SCREEN
		sw $t2, 0($t0)
		addi $t0, $t0, 4
		j WIN_SCREEN_LOOP
	DONE_WIN_SCREEN:
		jr $ra
		
DRAW_PLATFORMS:

	move $a0, $ra

	la $t0, platform1
	lw $a1, 0($t0)
	lw $a2, 4($t0)
	lw $a3, 8($t0)
	jal DRAW_SINGLE_PLATFORM
	la $t0, platform2
	lw $a1, 0($t0)
	lw $a2, 4($t0)
	lw $a3, 8($t0)
	jal DRAW_SINGLE_PLATFORM
	la $t0, platform3
	lw $a1, 0($t0)
	lw $a2, 4($t0)
	lw $a3, 8($t0)
	jal DRAW_SINGLE_PLATFORM
	la $t0, platform4
	lw $a1, 0($t0)
	lw $a2, 4($t0)
	lw $a3, 8($t0)
	jal DRAW_SINGLE_PLATFORM
	la $t0, platform5
	lw $a1, 0($t0)
	lw $a2, 4($t0)
	lw $a3, 8($t0)
	jal DRAW_SINGLE_PLATFORM
	la $t0, platform6
	lw $a1, 0($t0)
	lw $a2, 4($t0)
	lw $a3, 8($t0)
	jal DRAW_SINGLE_PLATFORM
	la $t0, platform7
	lw $a1, 0($t0)
	lw $a2, 4($t0)
	lw $a3, 8($t0)
	jal DRAW_SINGLE_PLATFORM
	la $t0, platform8
	lw $a1, 0($t0)
	lw $a2, 4($t0)
	lw $a3, 8($t0)
	jal DRAW_SINGLE_PLATFORM
	
	move $ra, $a0
	jr $ra
	
DRAW_SINGLE_PLATFORM: 

	li $t0, screenWidth
	li $t2, 4
	
	# Calculates start/end addresses
	mult $t0, $a2
	mflo $t0
	add $t0, $t0, $a1
	mult $t0, $t2
	mflo $t0
	addi $t0, $t0, BASE_ADDRESS
	move $t3, $a3
	mult $t2, $t3
	mflo $t3
	add $t3, $t0, $t3

	lw $t4, colorPlatform
	
	DRAW_SINGLE_PLATFORM_LOOP:
		bgt $t0, $t3, END_DRAW_SINGLE_PLATFORM_LOOP  
    		sw $t4, 0($t0)  
    		li $t5, screenWidth
		li $t6, 4           
    		mult $t5, $t6        
    		mflo $t7              
    		add $t1, $t0, $t7
    		sw $t4, 0($t1)
    		addi $t0, $t0, 4
    		j DRAW_SINGLE_PLATFORM_LOOP
	END_DRAW_SINGLE_PLATFORM_LOOP:
		jr $ra

DRAW_DOOR:

	move  $a0, $ra

	li $t0, 14 
	li $t1, 0
	li $t2, 1
	lw $t3, colorDoorClosed
	
	add $t9, $s5, $s6
	add $t9, $t9, $s7
	beq $t9, 0, DOOR_OPEN
	
	COLOR_DOOR:

	li $t4, BASE_ADDRESS
	li $t5, screenWidth
	li $t6, 4
	mult $t5, $t2 
	mflo $t5			
	add $t5, $t5, $t1
	mult $t5, $t6
	mflo $t5
	add $t5, $t5, $t4
	
	li $t4, 0 
	DRAW_DOOR_LOOP:
		bge $t4, $t0, END_DRAW_DOOR_LOOP
		sw $t3, 0($t5)
		addi $t5, $t5, 256
		addi $t4, $t4, 1
		j DRAW_DOOR_LOOP
	END_DRAW_DOOR_LOOP:
		jr $ra
		
	DOOR_OPEN:
		lw $t3, colorDoorOpen
		j COLOR_DOOR
	
DRAW_STAR1:
	
	la $t0, star1

	lw $t1, 0($t0)
	lw $t2, 4($t0)
	lw $t3, colorStar
	lw $t4, colorStarOutline
	
	beq $s5, 0, ERASE_STAR1

	COLOR_STAR1:

	li $t0, BASE_ADDRESS
	li $t5, screenWidth
	li $t6, 4
	mult $t5, $t2 
	mflo $t5			
	add $t5, $t5, $t1
	mult $t5, $t6
	mflo $t5
	add $t5, $t5, $t0
	# Row 1
	sw $t4, 16($t5)
	# Row 2
	addi $t5, $t5, 256
	sw $t4, 12($t5)
	sw $t3, 16($t5)
	sw $t4, 20($t5)
	# Row 3
	addi $t5, $t5, 256
	sw $t4, 4($t5)
	sw $t4, 8($t5)
	sw $t3, 12($t5)
	sw $t3, 16($t5)
	sw $t3, 20($t5)
	sw $t4, 24($t5)
	sw $t4, 28($t5)
	# Row 4
	addi $t5, $t5, 256
	sw $t4, 0($t5)
	sw $t3, 4($t5)
	sw $t3, 8($t5)
	sw $t3, 12($t5)
	sw $t3, 16($t5)
	sw $t3, 20($t5)
	sw $t3, 24($t5)
	sw $t3, 28($t5)
	sw $t4, 32($t5)
	# Row 5
	addi $t5, $t5, 256
	sw $t4, 4($t5)
	sw $t3, 8($t5)
	sw $t3, 12($t5)
	sw $t3, 16($t5)
	sw $t3, 20($t5)
	sw $t3, 24($t5)
	sw $t4, 28($t5)
	# Row 6
	addi $t5, $t5, 256
	sw $t4, 8($t5)
	sw $t3, 12($t5)
	sw $t3, 16($t5)
	sw $t3, 20($t5)
	sw $t4, 24($t5)
	# Row 7
	addi $t5, $t5, 256
	sw $t4, 8($t5)
	sw $t3, 12($t5)
	sw $t4, 16($t5)
	sw $t3, 20($t5)
	sw $t4, 24($t5)
	# Row 6
	addi $t5, $t5, 256
	sw $t4, 8($t5)
	sw $t4, 12($t5)
	sw $t4, 20($t5)
	sw $t4, 24($t5)
	
	END_DRAW_STAR1:	
		jr $ra
		
	ERASE_STAR1:
		lw $t3, colorBackground
		lw $t4, colorBackground
		j COLOR_STAR1
		

DRAW_STAR2:
	
	la $t0, star2

	lw $t1, 0($t0)
	lw $t2, 4($t0)
	lw $t3, colorStar
	lw $t4, colorStarOutline

	beq $s6, 0, ERASE_STAR2
	
	COLOR_STAR2:

	li $t0, BASE_ADDRESS
	li $t5, screenWidth
	li $t6, 4
	mult $t5, $t2 
	mflo $t5			
	add $t5, $t5, $t1
	mult $t5, $t6
	mflo $t5
	add $t5, $t5, $t0
	# Row 1
	sw $t4, 16($t5)
	# Row 2
	addi $t5, $t5, 256
	sw $t4, 12($t5)
	sw $t3, 16($t5)
	sw $t4, 20($t5)
	# Row 3
	addi $t5, $t5, 256
	sw $t4, 4($t5)
	sw $t4, 8($t5)
	sw $t3, 12($t5)
	sw $t3, 16($t5)
	sw $t3, 20($t5)
	sw $t4, 24($t5)
	sw $t4, 28($t5)
	# Row 4
	addi $t5, $t5, 256
	sw $t4, 0($t5)
	sw $t3, 4($t5)
	sw $t3, 8($t5)
	sw $t3, 12($t5)
	sw $t3, 16($t5)
	sw $t3, 20($t5)
	sw $t3, 24($t5)
	sw $t3, 28($t5)
	sw $t4, 32($t5)
	# Row 5
	addi $t5, $t5, 256
	sw $t4, 4($t5)
	sw $t3, 8($t5)
	sw $t3, 12($t5)
	sw $t3, 16($t5)
	sw $t3, 20($t5)
	sw $t3, 24($t5)
	sw $t4, 28($t5)
	# Row 6
	addi $t5, $t5, 256
	sw $t4, 8($t5)
	sw $t3, 12($t5)
	sw $t3, 16($t5)
	sw $t3, 20($t5)
	sw $t4, 24($t5)
	# Row 7
	addi $t5, $t5, 256
	sw $t4, 8($t5)
	sw $t3, 12($t5)
	sw $t4, 16($t5)
	sw $t3, 20($t5)
	sw $t4, 24($t5)
	# Row 6
	addi $t5, $t5, 256
	sw $t4, 8($t5)
	sw $t4, 12($t5)
	sw $t4, 20($t5)
	sw $t4, 24($t5)
	
	END_DRAW_STAR2:	
		jr $ra
		
	ERASE_STAR2:
		lw $t3, colorBackground
		lw $t4, colorBackground
		j COLOR_STAR2
		
DRAW_STAR3:
	
	la $t0, star3

	lw $t1, 0($t0)
	lw $t2, 4($t0)
	lw $t3, colorStar
	lw $t4, colorStarOutline
	
	beq $s7, 0, ERASE_STAR3

	COLOR_STAR3:
	li $t0, BASE_ADDRESS
	li $t5, screenWidth
	li $t6, 4
	mult $t5, $t2 
	mflo $t5			
	add $t5, $t5, $t1
	mult $t5, $t6
	mflo $t5
	add $t5, $t5, $t0
	# Row 1
	sw $t4, 16($t5)
	# Row 2
	addi $t5, $t5, 256
	sw $t4, 12($t5)
	sw $t3, 16($t5)
	sw $t4, 20($t5)
	# Row 3
	addi $t5, $t5, 256
	sw $t4, 4($t5)
	sw $t4, 8($t5)
	sw $t3, 12($t5)
	sw $t3, 16($t5)
	sw $t3, 20($t5)
	sw $t4, 24($t5)
	sw $t4, 28($t5)
	# Row 4
	addi $t5, $t5, 256
	sw $t4, 0($t5)
	sw $t3, 4($t5)
	sw $t3, 8($t5)
	sw $t3, 12($t5)
	sw $t3, 16($t5)
	sw $t3, 20($t5)
	sw $t3, 24($t5)
	sw $t3, 28($t5)
	sw $t4, 32($t5)
	# Row 5
	addi $t5, $t5, 256
	sw $t4, 4($t5)
	sw $t3, 8($t5)
	sw $t3, 12($t5)
	sw $t3, 16($t5)
	sw $t3, 20($t5)
	sw $t3, 24($t5)
	sw $t4, 28($t5)
	# Row 6
	addi $t5, $t5, 256
	sw $t4, 8($t5)
	sw $t3, 12($t5)
	sw $t3, 16($t5)
	sw $t3, 20($t5)
	sw $t4, 24($t5)
	# Row 7
	addi $t5, $t5, 256
	sw $t4, 8($t5)
	sw $t3, 12($t5)
	sw $t4, 16($t5)
	sw $t3, 20($t5)
	sw $t4, 24($t5)
	# Row 6
	addi $t5, $t5, 256
	sw $t4, 8($t5)
	sw $t4, 12($t5)
	sw $t4, 20($t5)
	sw $t4, 24($t5)
	
	END_DRAW_STAR3:	
		jr $ra
		
	ERASE_STAR3:
		lw $t3, colorBackground
		lw $t4, colorBackground
		j COLOR_STAR3

DRAW_PLAYER:
	
	move  $a0, $ra
	
	move $t1, $s0
	move $t2, $s1
	lw $t3, colorPlayer
	
	li $t4, BASE_ADDRESS
	li $t5, screenWidth
	li $t6, 4
	mult $t5, $t2 
	mflo $t5			
	add $t5, $t5, $t1
	mult $t5, $t6
	mflo $t5
	add $t5, $t5, $t4
	
	# Row 1
	sw $t3, 4($t5)
	sw $t3, 8($t5)
	sw $t3, 12($t5)
	# Row 2
	addi $t5, $t5, 256
	sw $t3, 0($t5)
	sw $t3, 16($t5)
	# Row 3
	addi $t5, $t5, 256
	sw $t3, 0($t5)
	sw $t3, 16($t5)
	# Row 4
	addi $t5, $t5, 256
	sw $t3, 4($t5)
	sw $t3, 8($t5)
	sw $t3, 12($t5)
	# Row 5
	addi $t5, $t5, 256
	sw $t3, 8($t5)
	# Row 6
	addi $t5, $t5, 256
	sw $t3, 0($t5)
	sw $t3, 8($t5)
	sw $t3, 16($t5)
	# Row 7
	addi $t5,$t5, 256
	sw $t3, 4($t5)
	sw $t3, 8($t5)
	sw $t3, 12($t5)
	# Row 8
	addi $t5, $t5, 256
	sw $t3, 8($t5)
	# Row 9
	addi $t5, $t5, 256
	sw $t3, 8($t5)
	# Row 10
	addi $t5, $t5, 256
	sw $t3, 4($t5)
	sw $t3, 12($t5)
	# Row 11
	addi $t5, $t5, 256
	sw $t3, 0($t5)
	sw $t3, 16($t5)
		
	move $ra, $a0
	jr $ra
	
ERASE_PLAYER:
	
	move $t1, $a1
	move $t2, $a2
	lw $t3, colorBackground
	
	li $t4, BASE_ADDRESS
	li $t5, screenWidth
	li $t6, 4
	mult $t5, $t2 
	mflo $t5			
	add $t5, $t5, $t1
	mult $t5, $t6
	mflo $t5
	add $t5, $t5, $t4
	
	
	
	# Row 1
	sw $t3, 4($t5)
	sw $t3, 8($t5)
	sw $t3, 12($t5)
	# Row 2
	addi $t5, $t5, 256
	sw $t3, 0($t5)
	sw $t3, 16($t5)
	# Row 3
	addi $t5, $t5, 256
	sw $t3, 0($t5)
	sw $t3, 16($t5)
	# Row 4
	addi $t5, $t5, 256
	sw $t3, 4($t5)
	sw $t3, 8($t5)
	sw $t3, 12($t5)
	# Row 5
	addi $t5, $t5, 256
	sw $t3, 8($t5)
	# Row 6
	addi $t5, $t5, 256
	sw $t3, 0($t5)
	sw $t3, 8($t5)
	sw $t3, 16($t5)
	# Row 7
	addi $t5,$t5, 256
	sw $t3, 4($t5)
	sw $t3, 8($t5)
	sw $t3, 12($t5)
	# Row 8
	addi $t5, $t5, 256
	sw $t3, 8($t5)
	# Row 9
	addi $t5, $t5, 256
	sw $t3, 8($t5)
	# Row 10
	addi $t5, $t5, 256
	sw $t3, 4($t5)
	sw $t3, 12($t5)
	# Row 11
	addi $t5, $t5, 256
	sw $t3, 0($t5)
	sw $t3, 16($t5)
	
	jr $ra
	
DRAW_GHOST:
	
	move  $a0, $ra
	
	move $t1, $s3
	move $t2, $s4
	lw $t3, colorGhost
	
	li $t4, BASE_ADDRESS
	li $t5, screenWidth
	li $t6, 4
	mult $t5, $t2 
	mflo $t5			
	add $t5, $t5, $t1
	mult $t5, $t6
	mflo $t5
	add $t5, $t5, $t4
	
	# Row 1
	sw $t3, 32($t5)
	sw $t3, 36($t5)
	sw $t3, 40($t5)
	# Row 2
	addi $t5, $t5, 256
	sw $t3, 28($t5)
	sw $t3, 44($t5)
	# Row 3
	addi $t5, $t5, 256
	sw $t3, 24($t5)
	sw $t3, 48($t5)
	# Row 4
	addi $t5, $t5, 256
	sw $t3, 20($t5)
	sw $t3, 32($t5)
	sw $t3, 40($t5)
	sw $t3, 48($t5)
	# Row 5
	addi $t5, $t5, 256
	sw $t3, 12($t5)
	sw $t3, 16($t5)
	sw $t3, 48($t5)
	# Row 6
	addi $t5, $t5, 256
	sw $t3, 8($t5)
	sw $t3, 36($t5)
	sw $t3, 44($t5)
	# Row 7
	addi $t5,$t5, 256
	sw $t3, 4($t5)
	sw $t3, 40($t5)
	# Row 8
	addi $t5, $t5, 256
	sw $t3, 8($t5)
	sw $t3, 12($t5)
	sw $t3, 36($t5)
	# Row 9
	addi $t5, $t5, 256
	sw $t3, 4($t5)
	sw $t3, 32($t5)
	# Row 10
	addi $t5, $t5, 256
	sw $t3, 0($t5)
	sw $t3, 28($t5)
	# Row 11
	addi $t5, $t5, 256
	sw $t3, 4($t5)
	sw $t3, 8($t5)
	sw $t3, 12($t5)
	sw $t3, 20($t5)
	sw $t3, 24($t5)
	sw $t3, 28($t5)
	# Row 12
	addi $t5, $t5, 256
	sw $t3, 12($t5)
	sw $t3, 16($t5)
		
	move $ra, $a0
	jr $ra
	
ERASE_GHOST:
	
	move  $a0, $ra
	
	move $t1, $s3
	move $t2, $s4
	lw $t3, colorBackground
	
	li $t4, BASE_ADDRESS
	li $t5, screenWidth
	li $t6, 4
	mult $t5, $t2 
	mflo $t5			
	add $t5, $t5, $t1
	mult $t5, $t6
	mflo $t5
	add $t5, $t5, $t4
	
	# Row 1
	sw $t3, 32($t5)
	sw $t3, 36($t5)
	sw $t3, 40($t5)
	# Row 2
	addi $t5, $t5, 256
	sw $t3, 28($t5)
	sw $t3, 44($t5)
	# Row 3
	addi $t5, $t5, 256
	sw $t3, 24($t5)
	sw $t3, 48($t5)
	# Row 4
	addi $t5, $t5, 256
	sw $t3, 20($t5)
	sw $t3, 32($t5)
	sw $t3, 40($t5)
	sw $t3, 48($t5)
	# Row 5
	addi $t5, $t5, 256
	sw $t3, 12($t5)
	sw $t3, 16($t5)
	sw $t3, 48($t5)
	# Row 6
	addi $t5, $t5, 256
	sw $t3, 8($t5)
	sw $t3, 36($t5)
	sw $t3, 44($t5)
	# Row 7
	addi $t5,$t5, 256
	sw $t3, 4($t5)
	sw $t3, 40($t5)
	# Row 8
	addi $t5, $t5, 256
	sw $t3, 8($t5)
	sw $t3, 12($t5)
	sw $t3, 36($t5)
	# Row 9
	addi $t5, $t5, 256
	sw $t3, 4($t5)
	sw $t3, 32($t5)
	# Row 10
	addi $t5, $t5, 256
	sw $t3, 0($t5)
	sw $t3, 28($t5)
	# Row 11
	addi $t5, $t5, 256
	sw $t3, 4($t5)
	sw $t3, 8($t5)
	sw $t3, 12($t5)
	sw $t3, 20($t5)
	sw $t3, 24($t5)
	sw $t3, 28($t5)
	# Row 12
	addi $t5, $t5, 256
	sw $t3, 12($t5)
	sw $t3, 16($t5)
		
	move $ra, $a0
	jr $ra
	

###################################################
#                       INPUT
###################################################
	
CHECK_INPUT:	
	li $t9, 0xffff0000
	lw $t8, 0($t9)
	beq $t8, 1, HANDLE_INPUT
	jr $ra
	
HANDLE_INPUT:
	lw $t0, 4($t9)
	beq $t0, keyW, WPressed
	beq $t0, keyA, APressed
	beq $t0, keyD, DPressed
	beq $t0, keyR, RPressed
	beq $t0, keyQ, QPressed
	beq $t0, keyG, GPressed
	beq $t0, keyN, NPressed
	jr $ra
	
	WPressed:
	
		PLATFORM1_WPressed:
		la $t0, platform1
		lw $t1, 0($t0)
		lw $t2, 4($t0)
		lw $t3, 8($t0)
		add $t4, $t1, $t3
		lw $t9, playerWidth	
		add $t5, $s0, $t9
		bgt $s0, $t4, PLATFORM2_WPressed
		ble $t5, $t1, PLATFORM2_WPressed
		ble $s1, $t2, PLATFORM2_WPressed
		la $t0, platform0
		lw $t2, 4($t0)
		blt $s1, $t2, END_WPressed
	
		PLATFORM2_WPressed:
		la $t0, platform2
		lw $t1, 0($t0)
		lw $t2, 4($t0)
		lw $t3, 8($t0)
		add $t4, $t1, $t3
		lw $t9, playerWidth	
		add $t5, $s0, $t9
		bgt $s0, $t4, PLATFORM3_WPressed
		ble $t5, $t1, PLATFORM3_WPressed
		ble $s1, $t2, PLATFORM3_WPressed
		la $t0, platform0
		lw $t2, 4($t0)
		blt $s1, $t2, END_WPressed
	
		PLATFORM3_WPressed:
		la $t0, platform3
		lw $t1, 0($t0)
		lw $t2, 4($t0)
		lw $t3, 8($t0)
		add $t4, $t1, $t3
		lw $t9, playerWidth
		add $t5, $s0, $t9
		bgt $s0, $t4, PLATFORM4_WPressed
		ble $t5, $t1, PLATFORM4_WPressed
		ble $s1, $t2, PLATFORM4_WPressed
		la $t0, platform0
		lw $t2, 4($t0)
		blt $s1, $t2, END_WPressed
	
	
		PLATFORM4_WPressed:
		la $t0, platform4
		lw $t1, 0($t0)
		lw $t2, 4($t0)
		lw $t3, 8($t0)
		add $t4, $t1, $t3
		lw $t9, playerWidth	
		add $t5, $s0, $t9
		bgt $s0, $t4, PLATFORM5_WPressed
		ble $t5, $t1, PLATFORM5_WPressed
		ble $s1, $t2, PLATFORM5_WPressed
		la $t0, platform6
		lw $t2, 4($t0)
		blt $s1, $t2, END_WPressed
	
		PLATFORM5_WPressed:
		la $t0, platform5
		lw $t1, 0($t0)
		lw $t2, 4($t0)
		lw $t3, 8($t0)
		add $t4, $t1, $t3
		lw $t9, playerWidth	
		add $t5, $s0, $t9
		bgt $s0, $t4, PLATFORM6_WPressed
		ble $t5, $t1, PLATFORM6_WPressed
		ble $s1, $t2, PLATFORM6_WPressed
		la $t0, platform6
		lw $t2, 4($t0)
		blt $s1, $t2, END_WPressed
	
		PLATFORM6_WPressed:
		la $t0, platform6
		lw $t1, 0($t0)
		lw $t2, 4($t0)
		lw $t3, 8($t0)
		add $t4, $t1, $t3
		lw $t9, playerWidth	
		add $t5, $s0, $t9
		bgt $s0, $t4, PLATFORM7_WPressed
		ble $t5, $t1, PLATFORM7_WPressed
		ble $s1, $t2, PLATFORM7_WPressed
		la $t0, platform8
		lw $t2, 4($t0)
		blt $s1, $t2, END_WPressed
		
		PLATFORM7_WPressed:
		la $t0, platform7
		lw $t1, 0($t0)
		lw $t2, 4($t0)
		lw $t3, 8($t0)
		add $t4, $t1, $t3
		lw $t9, playerWidth	
		add $t5, $s0, $t9
		bgt $s0, $t4, NEXT_WPressed
		ble $t5, $t1, NEXT_WPressed
		ble $s1, $t2, NEXT_WPressed
		la $t0, platform8
		lw $t2, 4($t0)
		blt $s1, $t2, END_WPressed
		
		NEXT_WPressed:
		beq $s2, 1, END_WPressed
		
		move $a1, $s0
		move $a2, $s1
		jal ERASE_PLAYER
		lw $t9, playerVerticalVelocity
		sub $s1, $s1, $t9
		jal DRAW_PLAYER
		li $v0, 32
  		li $a0, sleepDuration
    		syscall
		move $a1, $s0
		move $a2, $s1
		jal ERASE_PLAYER
		lw $t9, playerVerticalVelocity
		sub $s1, $s1, $t9
		jal DRAW_PLAYER
		li $v0, 32
  		li $a0, sleepDuration
    		syscall
		move $a1, $s0
		move $a2, $s1
		jal ERASE_PLAYER
		lw $t9, playerVerticalVelocity
		sub $s1, $s1, $t9
		jal DRAW_PLAYER
		li $v0, 32
  		li $a0, sleepDuration
    		syscall
		
		END_WPressed:
			j UPDATE_LOCATION
		
	APressed:
	
		move $a1, $s0
		move $a2, $s1
		jal ERASE_PLAYER
		lw $t9, playerHorizentalVelocity 
		sub $s0, $s0, $t9
		j GAME_LOOP
	DPressed:
		move $a1, $s0
		move $a2, $s1
		jal ERASE_PLAYER
		lw $t9, playerHorizentalVelocity 
		add $s0, $s0, $t9
		j GAME_LOOP
	RPressed:
		j main
	QPressed:
		j END
	NPressed:
		j DRAW_LEVEL_NOGHOST
	GPressed:
		j DRAW_LEVEL

###################################################
#             COLLISION AND MOVEMENT
###################################################	

CHECK_BOUNDS:

	li $t0, screenWidth
	lw $t9, playerWidth
	sub $t0, $t0, $t9
	
	ble $s0, 0, LEFT_BOUND
	bgt $s0, $t0, RIGHT_BOUND
	ble $s1, -5, TOP_BOUND
	
	
	jr $ra
		
	LEFT_BOUND:	
		li $s0, 0
		jr $ra
	RIGHT_BOUND:
		move $s0, $t0
		jr $ra
	TOP_BOUND:
		li $s1, -5
		jr $ra
		
CHECK_GROUNDED:

     	PLATFORM1_CHECK_GROUNDED:
    	la $t0, platform1
    	lw $t1, 0($t0)
    	lw $t2, 4($t0)
    	lw $t3, 8($t0)
    	lw $t9, playerHeight
    	add $t4, $s1, $t9
    	add $t4, $t4, 1
    	addi $t5, $s0, 3
    	blt $t5, $t1, PLATFORM2_CHECK_GROUNDED
    	add $t1, $t1, $t3
    	bgt $s0, $t1, PLATFORM2_CHECK_GROUNDED
    	beq $t4, $t2, PLAYER_GROUNDED  

     	PLATFORM2_CHECK_GROUNDED:
    	la $t0, platform2
    	lw $t1, 0($t0)
    	lw $t2, 4($t0)
    	lw $t3, 8($t0)
 	lw $t9, playerHeight
    	add $t4, $s1, $t9
    	add $t4, $t4, 1
    	addi $t5, $s0, 3
    	blt $t5, $t1, PLATFORM3_CHECK_GROUNDED
    	add $t1, $t1, $t3
    	bgt $s0, $t1, PLATFORM3_CHECK_GROUNDED
    	beq $t4, $t2, PLAYER_GROUNDED  
 
      	PLATFORM3_CHECK_GROUNDED:
    	la $t0, platform3
    	lw $t1, 0($t0)
    	lw $t2, 4($t0)
    	lw $t3, 8($t0)
    	lw $t9, playerHeight
    	add $t4, $s1, $t9
    	add $t4, $t4, 1
    	addi $t5, $s0, 3
    	blt $t5, $t1, PLATFORM4_CHECK_GROUNDED
    	add $t1, $t1, $t3
    	bgt $s0, $t1, PLATFORM4_CHECK_GROUNDED
    	beq $t4, $t2, PLAYER_GROUNDED  
    	
     	PLATFORM4_CHECK_GROUNDED:
    	la $t0, platform4
    	lw $t1, 0($t0)
    	lw $t2, 4($t0)
    	lw $t3, 8($t0)
    	lw $t9, playerHeight
    	add $t4, $s1, $t9
    	add $t4, $t4, 1
    	addi $t5, $s0, 3
    	blt $t5, $t1, PLATFORM5_CHECK_GROUNDED
    	add $t1, $t1, $t3
    	bgt $s0, $t1, PLATFORM5_CHECK_GROUNDED
    	beq $t4, $t2, PLAYER_GROUNDED  
    	
     	PLATFORM5_CHECK_GROUNDED:
    	la $t0, platform5
    	lw $t1, 0($t0)
    	lw $t2, 4($t0)
    	lw $t3, 8($t0)
     	lw $t9, playerHeight
    	add $t4, $s1, $t9
    	add $t4, $t4, 1
    	addi $t5, $s0, 3
    	blt $t5, $t1, PLATFORM6_CHECK_GROUNDED
    	add $t1, $t1, $t3
    	bgt $s0, $t1, PLATFORM6_CHECK_GROUNDED
    	beq $t4, $t2, PLAYER_GROUNDED  

     	PLATFORM6_CHECK_GROUNDED:
    	la $t0, platform6
    	lw $t1, 0($t0)
    	lw $t2, 4($t0)
    	lw $t3, 8($t0)
     	lw $t9, playerHeight
    	add $t4, $s1, $t9
    	add $t4, $t4, 1
    	addi $t5, $s0, 3
    	blt $t5, $t1, PLATFORM7_CHECK_GROUNDED
    	add $t1, $t1, $t3
    	bgt $s0, $t1, PLATFORM7_CHECK_GROUNDED
    	beq $t4, $t2, PLAYER_GROUNDED  
    	
     	PLATFORM7_CHECK_GROUNDED:
    	la $t0, platform7
    	lw $t1, 0($t0)
    	lw $t2, 4($t0)
    	lw $t3, 8($t0)
     	lw $t9, playerHeight
    	add $t4, $s1, $t9
    	add $t4, $t4, 1
    	addi $t5, $s0, 3
    	blt $t5, $t1, PLATFORM8_CHECK_GROUNDED
    	add $t1, $t1, $t3
    	bgt $s0, $t1, PLATFORM8_CHECK_GROUNDED
    	beq $t4, $t2, PLAYER_GROUNDED  
    	
    	PLATFORM8_CHECK_GROUNDED:
    	la $t0, platform8
    	lw $t1, 0($t0)
    	lw $t2, 4($t0)
    	sub $t2, $t2, $s1
    	sub $t2, $t2, 11
    	blez $t2, PLAYER_GROUNDED
    	
       
    	li $s2, 1                   
    	j CHECK_GROUNDED_END
    
	PLAYER_GROUNDED:
    		li $s2, 0                 
    
	CHECK_GROUNDED_END:
    		jr $ra                    

APPLY_GS:
    	li $t0, 0
    	beq $s2, $t0, DONE_GS      

   	move $a1, $s0               
   	move $a2, $s1                    
    	addi $s1, $s1, GRAV_ACCEL   
    	DONE_GS:
    		jr $ra
    	
UPDATE_LOCATION:
    addi $sp, $sp, -4  
    sw $ra, 0($sp)      

    move $a1, $s0
    move $a2, $s1
    jal ERASE_PLAYER
    jal CHECK_BOUNDS
    jal APPLY_GS
    jal DRAW_PLAYER
    
    lw $ra, 0($sp)     
    addi $sp, $sp, 4    
    
    li $v0, 32
    li $a0, sleepDuration
    syscall

    j GAME_LOOP


	
			
UPDATE_GHOST_LOCATION:
    lw $t4, ghostWidth
    li $t5, screenWidth
    li $t6, screenHeight
    sub $t5, $t5, $t4   
    sub $t5, $t5, 3    

    bge $s3, $t5, RESET_GHOST_POSITION
    blez $s4, RESET_GHOST_POSITION2


   
    addi $sp, $sp, -4 
    sw $ra, 0($sp)     

    move $a1, $s3       
    move $a2, $s4
    jal ERASE_GHOST
    
    lw $t9, ghostHorizentalVelocity
    add $s3, $s3, $t9   
    jal DRAW_GHOST

    lw $ra, 0($sp)      
    addi $sp, $sp, 4    
    jr $ra             

RESET_GHOST_POSITION:
    addi $sp, $sp, -4   
    sw $ra, 0($sp)     

    move $a1, $s3       
    move $a2, $s4       
    jal ERASE_GHOST 

    sub $s3, $s3, $s3 
    sub $s4, $s4, 16    

    lw $ra, 0($sp)     
    addi $sp, $sp, 4   
    jr $ra             

   RESET_GHOST_POSITION2:
    addi $sp, $sp, -4   
    sw $ra, 0($sp)      

    move $a1, $s3      
    move $a2, $s4       
    jal ERASE_GHOST

    sub $s3, $s3, $s3   
    add $s4, $s4, 64    

    lw $ra, 0($sp)      
    addi $sp, $sp, 4   
    jr $ra              
   
CHECK_STARS_COLLISION:
	
	CHECK_STAR1:
	lw $t0, playerWidth
     	lw $t1, playerHeight
     	la $t4, star1
     	lw $t3, 0($t4)
     	lw $t4, 4($t4)
	
	add $t5, $s0, $t0
	blt $t5, $t3, CHECK_STAR2
	add $t6, $t3, $8
	bgt $s0, $t6, CHECK_STAR2
	
	add $t7, $t4, $6
	bgt $s1, $t7, CHECK_STAR2
	add $t7, $s1, $t1
	blt $t7, $t4, CHECK_STAR2
	
	sub $t7, $s1, $t4
	bgt $t7, 2, CHECK_STAR2
	
	li $s5, 0
	
	CHECK_STAR2:
	
	lw $t0, playerWidth
     	lw $t1, playerHeight
     	la $t4, star2
     	lw $t3, 0($t4)
     	lw $t4, 4($t4)
	
	add $t5, $s0, $t0
	blt $t5, $t3, CHECK_STAR3
	add $t6, $t3, $8
	bgt $s0, $t6, CHECK_STAR3
	
	add $t7, $t4, $6
	bgt $s1, $t7, CHECK_STAR3
	add $t7, $s1, $t1
	blt $t7, $t4, CHECK_STAR3
	
	sub $t7, $s1, $t4
	bgt $t7, 2, CHECK_STAR3
	
	li $s6, 0
	
	CHECK_STAR3:
	lw $t0, playerWidth
     	lw $t1, playerHeight
     	la $t4, star3
     	lw $t3, 0($t4)
     	lw $t4, 4($t4)
	
	add $t5, $s0, $t0
	blt $t5, $t3, END_CHECK
	add $t6, $t3, $8
	bgt $s0, $t6, END_CHECK
	
	add $t7, $t4, $6
	bgt $s1, $t7, END_CHECK
	add $t7, $s1, $t1
	blt $t7, $t4, END_CHECK
	
	sub $t7, $s1, $t4
	bgt $t7, 2, END_CHECK
	
	li $s7, 0
		
	END_CHECK:
		jr $ra

CHECK_GHOST_COLLISION:
     	lw $t0, playerWidth
     	lw $t1, playerHeight
	lw $t3, ghostWidth
	lw $t4, ghostHeight
	
	add $t5, $s0, $t0
	blt $t5, $s3, END_CHECK_GHOST_COLLISION
	add $t6, $s3, $t3
	bgt $s0, $t6, END_CHECK_GHOST_COLLISION
	
	add $t7, $s4, $t4
	bgt $s1, $t7, END_CHECK_GHOST_COLLISION
	add $t7, $s1, $t1
	blt $t7, $s4, END_CHECK_GHOST_COLLISION
	
	sub $t7, $s1, $s4
	ble $t7, 2, GHOST_COLLISION
		
	END_CHECK_GHOST_COLLISION:
		jr $ra
		
	GHOST_COLLISION:
		j LOSE
		
		
		
		

	
CHECK_INPUTG:	
	li $t9, 0xffff0000
	lw $t8, 0($t9)
	beq $t8, 1, HANDLE_INPUTG
	jr $ra
	
HANDLE_INPUTG:
	lw $t0, 4($t9)
	beq $t0, keyW, WPressedG
	beq $t0, keyA, APressedG
	beq $t0, keyD, DPressedG
	beq $t0, keyR, RPressedG
	beq $t0, keyQ, QPressedG
	beq $t0, keyG, GPressedG
	beq $t0, keyN, NPressedG
	jr $ra
	
	WPressedG:
	
		PLATFORM1_WPressedG:
		la $t0, platform1
		lw $t1, 0($t0)
		lw $t2, 4($t0)
		lw $t3, 8($t0)
		add $t4, $t1, $t3
		lw $t9, playerWidth	
		add $t5, $s0, $t9
		bgt $s0, $t4, PLATFORM2_WPressedG
		ble $t5, $t1, PLATFORM2_WPressedG
		ble $s1, $t2, PLATFORM2_WPressedG
		la $t0, platform0
		lw $t2, 4($t0)
		blt $s1, $t2, END_WPressedG
	
		PLATFORM2_WPressedG:
		la $t0, platform2
		lw $t1, 0($t0)
		lw $t2, 4($t0)
		lw $t3, 8($t0)
		add $t4, $t1, $t3
		lw $t9, playerWidth	
		add $t5, $s0, $t9
		bgt $s0, $t4, PLATFORM3_WPressedG
		ble $t5, $t1, PLATFORM3_WPressedG
		ble $s1, $t2, PLATFORM3_WPressedG
		la $t0, platform0
		lw $t2, 4($t0)
		blt $s1, $t2, END_WPressedG
	
		PLATFORM3_WPressedG:
		la $t0, platform3
		lw $t1, 0($t0)
		lw $t2, 4($t0)
		lw $t3, 8($t0)
		add $t4, $t1, $t3
		lw $t9, playerWidth
		add $t5, $s0, $t9
		bgt $s0, $t4, PLATFORM4_WPressedG
		ble $t5, $t1, PLATFORM4_WPressedG
		ble $s1, $t2, PLATFORM4_WPressedG
		la $t0, platform0
		lw $t2, 4($t0)
		blt $s1, $t2, END_WPressedG
	
	
		PLATFORM4_WPressedG:
		la $t0, platform4
		lw $t1, 0($t0)
		lw $t2, 4($t0)
		lw $t3, 8($t0)
		add $t4, $t1, $t3
		lw $t9, playerWidth	
		add $t5, $s0, $t9
		bgt $s0, $t4, PLATFORM5_WPressedG
		ble $t5, $t1, PLATFORM5_WPressedG
		ble $s1, $t2, PLATFORM5_WPressedG
		la $t0, platform6
		lw $t2, 4($t0)
		blt $s1, $t2, END_WPressedG
	
		PLATFORM5_WPressedG:
		la $t0, platform5
		lw $t1, 0($t0)
		lw $t2, 4($t0)
		lw $t3, 8($t0)
		add $t4, $t1, $t3
		lw $t9, playerWidth	
		add $t5, $s0, $t9
		bgt $s0, $t4, PLATFORM6_WPressedG
		ble $t5, $t1, PLATFORM6_WPressedG
		ble $s1, $t2, PLATFORM6_WPressedG
		la $t0, platform6
		lw $t2, 4($t0)
		blt $s1, $t2, END_WPressedG
	
		PLATFORM6_WPressedG:
		la $t0, platform6
		lw $t1, 0($t0)
		lw $t2, 4($t0)
		lw $t3, 8($t0)
		add $t4, $t1, $t3
		lw $t9, playerWidth	
		add $t5, $s0, $t9
		bgt $s0, $t4, PLATFORM7_WPressedG
		ble $t5, $t1, PLATFORM7_WPressedG
		ble $s1, $t2, PLATFORM7_WPressedG
		la $t0, platform8
		lw $t2, 4($t0)
		blt $s1, $t2, END_WPressedG
		
		PLATFORM7_WPressedG:
		la $t0, platform7
		lw $t1, 0($t0)
		lw $t2, 4($t0)
		lw $t3, 8($t0)
		add $t4, $t1, $t3
		lw $t9, playerWidth	
		add $t5, $s0, $t9
		bgt $s0, $t4, NEXT_WPressedG
		ble $t5, $t1, NEXT_WPressedG
		ble $s1, $t2, NEXT_WPressedG
		la $t0, platform8
		lw $t2, 4($t0)
		blt $s1, $t2, END_WPressedG
		
		NEXT_WPressedG:
		beq $s2, 1, END_WPressedG
		
		move $a1, $s0
		move $a2, $s1
		jal ERASE_PLAYER
		lw $t9, playerVerticalVelocity
		sub $s1, $s1, $t9
		jal DRAW_PLAYER
		li $v0, 32
  		li $a0, sleepDuration
    		syscall
		move $a1, $s0
		move $a2, $s1
		jal ERASE_PLAYER
		lw $t9, playerVerticalVelocity
		sub $s1, $s1, $t9
		jal DRAW_PLAYER
		li $v0, 32
  		li $a0, sleepDuration
    		syscall
		move $a1, $s0
		move $a2, $s1
		jal ERASE_PLAYER
		lw $t9, playerVerticalVelocity
		sub $s1, $s1, $t9
		jal DRAW_PLAYER
		li $v0, 32
  		li $a0, sleepDuration
    		syscall
		
		END_WPressedG:
			j UPDATE_LOCATIONG
		
	APressedG:
	
		move $a1, $s0
		move $a2, $s1
		jal ERASE_PLAYER
		lw $t9, playerHorizentalVelocity 
		sub $s0, $s0, $t9
		j GAME_LOOP_NOGHOST
	DPressedG:
		move $a1, $s0
		move $a2, $s1
		jal ERASE_PLAYER
		lw $t9, playerHorizentalVelocity 
		add $s0, $s0, $t9
		j GAME_LOOP_NOGHOST
	RPressedG:
		j main
	QPressedG:
		j END
	NPressedG:
		j DRAW_LEVEL_NOGHOST
	GPressedG:
		j DRAW_LEVEL

###################################################
#             COLLISION AND MOVEMENT
###################################################	

CHECK_BOUNDSG:

	li $t0, screenWidth
	lw $t9, playerWidth	
	sub $t0, $t0, $t9
	
	ble $s0, 0, LEFT_BOUNDG
	bgt $s0, $t0, RIGHT_BOUNDG
	ble $s1, -5, TOP_BOUNDG
	
	
	jr $ra
		
	LEFT_BOUNDG:	
		li $s0, 0
		jr $ra
	RIGHT_BOUNDG:
		move $s0, $t0
		jr $ra
	TOP_BOUNDG:
		li $s1, -5
		jr $ra
		
CHECK_GROUNDEDG:

     	PLATFORM1_CHECK_GROUNDEDG:
    	la $t0, platform1
    	lw $t1, 0($t0)
    	lw $t2, 4($t0)
    	lw $t3, 8($t0)
    	lw $t9, playerHeight
    	add $t4, $s1, $t9
    	add $t4, $t4, 1
    	addi $t5, $s0, 3
    	blt $t5, $t1, PLATFORM2_CHECK_GROUNDEDG
    	add $t1, $t1, $t3
    	bgt $s0, $t1, PLATFORM2_CHECK_GROUNDEDG
    	beq $t4, $t2, PLAYER_GROUNDEDG 

     	PLATFORM2_CHECK_GROUNDEDG:
    	la $t0, platform2
    	lw $t1, 0($t0)
    	lw $t2, 4($t0)
    	lw $t3, 8($t0)
 	lw $t9, playerHeight
    	add $t4, $s1, $t9
    	add $t4, $t4, 1
    	addi $t5, $s0, 3
    	blt $t5, $t1, PLATFORM3_CHECK_GROUNDEDG
    	add $t1, $t1, $t3
    	bgt $s0, $t1, PLATFORM3_CHECK_GROUNDEDG
    	beq $t4, $t2, PLAYER_GROUNDEDG  
 
      	PLATFORM3_CHECK_GROUNDEDG:
    	la $t0, platform3
    	lw $t1, 0($t0)
    	lw $t2, 4($t0)
    	lw $t3, 8($t0)
    	lw $t9, playerHeight
    	add $t4, $s1, $t9
    	add $t4, $t4, 1
    	addi $t5, $s0, 3
    	blt $t5, $t1, PLATFORM4_CHECK_GROUNDEDG
    	add $t1, $t1, $t3
    	bgt $s0, $t1, PLATFORM4_CHECK_GROUNDEDG
    	beq $t4, $t2, PLAYER_GROUNDEDG  
    	
     	PLATFORM4_CHECK_GROUNDEDG:
    	la $t0, platform4
    	lw $t1, 0($t0)
    	lw $t2, 4($t0)
    	lw $t3, 8($t0)
    	lw $t9, playerHeight
    	add $t4, $s1, $t9
    	add $t4, $t4, 1
    	addi $t5, $s0, 3
    	blt $t5, $t1, PLATFORM5_CHECK_GROUNDEDG
    	add $t1, $t1, $t3
    	bgt $s0, $t1, PLATFORM5_CHECK_GROUNDEDG
    	beq $t4, $t2, PLAYER_GROUNDEDG 
    	
     	PLATFORM5_CHECK_GROUNDEDG:
    	la $t0, platform5
    	lw $t1, 0($t0)
    	lw $t2, 4($t0)
    	lw $t3, 8($t0)
     	lw $t9, playerHeight
    	add $t4, $s1, $t9
    	add $t4, $t4, 1
    	addi $t5, $s0, 3
    	blt $t5, $t1, PLATFORM6_CHECK_GROUNDEDG
    	add $t1, $t1, $t3
    	bgt $s0, $t1, PLATFORM6_CHECK_GROUNDEDG
    	beq $t4, $t2, PLAYER_GROUNDEDG  

     	PLATFORM6_CHECK_GROUNDEDG:
    	la $t0, platform6
    	lw $t1, 0($t0)
    	lw $t2, 4($t0)
    	lw $t3, 8($t0)
     	lw $t9, playerHeight
    	add $t4, $s1, $t9
    	add $t4, $t4, 1
    	addi $t5, $s0, 3
    	blt $t5, $t1, PLATFORM7_CHECK_GROUNDEDG
    	add $t1, $t1, $t3
    	bgt $s0, $t1, PLATFORM7_CHECK_GROUNDEDG
    	beq $t4, $t2, PLAYER_GROUNDEDG  
    	
     	PLATFORM7_CHECK_GROUNDEDG:
    	la $t0, platform7
    	lw $t1, 0($t0)
    	lw $t2, 4($t0)
    	lw $t3, 8($t0)
     	lw $t9, playerHeight
    	add $t4, $s1, $t9
    	add $t4, $t4, 1
    	addi $t5, $s0, 3
    	blt $t5, $t1, PLATFORM8_CHECK_GROUNDEDG
    	add $t1, $t1, $t3
    	bgt $s0, $t1, PLATFORM8_CHECK_GROUNDEDG
    	beq $t4, $t2, PLAYER_GROUNDEDG  
    	
    	PLATFORM8_CHECK_GROUNDEDG:
    	la $t0, platform8
    	lw $t1, 0($t0)
    	lw $t2, 4($t0)
    	sub $t2, $t2, $s1
    	sub $t2, $t2, 11
    	blez $t2, PLAYER_GROUNDEDG
    	
       
    	li $s2, 1                  
    	j CHECK_GROUNDED_ENDG
    
	PLAYER_GROUNDEDG:
    		li $s2, 0                  
    
	CHECK_GROUNDED_ENDG:
    		jr $ra                     

APPLY_GSG:
    	li $t0, 0
    	beq $s2, $t0, DONE_GS      
   	move $a1, $s0              
   	move $a2, $s1           
    	addi $s1, $s1, GRAV_ACCEL
    	DONE_GSG:
    		jr $ra
    	
UPDATE_LOCATIONG:
    addi $sp, $sp, -4  
    sw $ra, 0($sp)    

    move $a1, $s0
    move $a2, $s1
    jal ERASE_PLAYER
    jal CHECK_BOUNDS
    jal APPLY_GSG
    jal DRAW_PLAYER
    
    lw $ra, 0($sp)   
    addi $sp, $sp, 4   
    
    li $v0, 32
    li $a0, sleepDuration
    syscall

    j GAME_LOOP_NOGHOST


CHECK_STARS_COLLISIONG:
	
	CHECK_STAR1G:
	lw $t0, playerWidth
     	lw $t1, playerHeight
     	la $t4, star1
     	lw $t3, 0($t4)
     	lw $t4, 4($t4)
	
	add $t5, $s0, $t0
	blt $t5, $t3, CHECK_STAR2G
	add $t6, $t3, $8
	bgt $s0, $t6, CHECK_STAR2G
	
	add $t7, $t4, $6
	bgt $s1, $t7, CHECK_STAR2G
	add $t7, $s1, $t1
	blt $t7, $t4, CHECK_STAR2G
	
	sub $t7, $s1, $t4
	bgt $t7, 2, CHECK_STAR2G
	
	li $s5, 0
	
	CHECK_STAR2G:
	
	lw $t0, playerWidth
     	lw $t1, playerHeight
     	la $t4, star2
     	lw $t3, 0($t4)
     	lw $t4, 4($t4)
	
	add $t5, $s0, $t0
	blt $t5, $t3, CHECK_STAR3G
	add $t6, $t3, $8
	bgt $s0, $t6, CHECK_STAR3G
	
	add $t7, $t4, $6
	bgt $s1, $t7, CHECK_STAR3G
	add $t7, $s1, $t1
	blt $t7, $t4, CHECK_STAR3G
	
	sub $t7, $s1, $t4
	bgt $t7, 2, CHECK_STAR3G
	
	li $s6, 0
	
	CHECK_STAR3G:
	lw $t0, playerWidth
     	lw $t1, playerHeight
     	la $t4, star3
     	lw $t3, 0($t4)
     	lw $t4, 4($t4)
	
	add $t5, $s0, $t0
	blt $t5, $t3, END_CHECKG
	add $t6, $t3, $8
	bgt $s0, $t6, END_CHECKG
	
	add $t7, $t4, $6
	bgt $s1, $t7, END_CHECKG
	add $t7, $s1, $t1
	blt $t7, $t4, END_CHECKG
	
	sub $t7, $s1, $t4
	bgt $t7, 2, END_CHECKG
	
	li $s7, 0
		
	END_CHECKG:
		jr $ra
		
DOOR_COLLISION:
	bne $s0, 0, END_CHECK_DOOR_COLLISION
	bgt $s1, 14, END_CHECK_DOOR_COLLISION
	add $t9, $s5, $s6
	add $t9, $t9, $s7
	beq $t9, 0, WIN
	
	END_CHECK_DOOR_COLLISION:
		jr $ra
