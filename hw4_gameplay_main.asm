.include "hw4_ftang3.asm"
.include "hw4_ec_ftang3.asm"
.include "hw4_helpers.asm"
.data
welcome: .asciiz "===============================\nWelcome to ICS51 Sudoku\n===============================\n"

fg_preset_str: .asciiz "\nEnter a number [0-15] for the preset cell foreground color: "
bg_preset_str: .asciiz "\nEnter a number [0-15] for the preset cell background color: "
bg_error_str: .asciiz "\nEnter a number [0-15] for the error background color: "
enter_move_str: .asciiz "\nEnter move (RCV), 'R' to restart game, 'Q' to quit: "
#enter_move_str: .asciiz "\nEnter move (RCV), 'R' to restart game, 'H' for hint, 'Q' to quit: "
#enter_move_str: .asciiz "\nEnter move (RCV), 'R' to restart game, 'S' to save board, 'Q' to quit: "
#enter_move_str: .asciiz "\nEnter move (RCV), 'R' to restart game, 'S' to save board, 'H' for hint, 'Q' to quit: "
invalid_color_str: .asciiz "\nInvalid color! Try again.\n"
invalid_colorSet_str: .asciiz "\nColor combinations can't be used! Try again.\n"
main_filename_str: .asciiz "\nLoad Game - Enter the name of the file (max 47 chars): "
main_filename_error_str: .asciiz "Error with loading board from file! Try again\n"
main_save_str: .asciiz "\nSave Game - Enter the name of the file (max 47 chars): "
main_save_game_str: .asciiz "\nGame Saved!\n"
main_save_error_str: .asciiz "Error with saving board to file!\n"
main_hint_str: .asciiz "Enter board position for hint (RC): "
main_hint_response: .asciiz "The following values can be placed: "
game_won_str: .asciiz "\nYou Won!!!!\nGAME OVER\n"
main_game_error_str: .asciiz "\nGameboard error! GOODBYE\n"
invalid_move_str: .asciiz "Move is invalid. Try again.\n"
conflicts_str: .asciiz "Conflict! Value can not be placed in board. Try again.\n"
.text 
.globl main

# $a0: address of string
__replaceNewline:
	lb $t0, 0($a0)
	beqz $t0, __replaceNewline_done
    li $t1, '\n'
	beq $t0, $t1, __replaceNewline_found
	addi $a0, $a0, 1
	j __replaceNewline
__replaceNewline_found:
	sb $0, 0($a0)
__replaceNewline_done:
	jr $ra


# $a0, string to print
# $v0, return color
__inputColor:
	move $t1, $a0 
	li $v0, 4
	syscall

	li $v0, 5
	syscall

	bltz $v0, __inputColor_err
    li $t0, 15
	bgt $v0, $t0, __inputColor_err
    jr $ra

__inputColor_err:
    li $v0, 4
    la $a0, invalid_color_str
	syscall
	move $a0, $t1
	j __inputColor


main:
	# print welcome message
	li $v0, 4
	la $a0, welcome
	syscall

main_enterColors:
	# Prompt and get the colors by user
    la $a0, bg_preset_str
    jal __inputColor
    move $s2, $v0

    la $a0, fg_preset_str
    jal __inputColor
    move $s3, $v0

    la $a0, bg_error_str
    jal __inputColor
    move $s4, $v0

	# Check the colors inputted by users
	move $a0, $s2   # pc_bg
	move $a1, $s3   # pc_fg
	li $a2, 0xF	# gc_bg  always white bg (to work with reset)
	li $a3, 0   # gc_fg  always black fg (to work with reset)
	addi $sp, $sp, -4   # load 5th argument on the stack
	sw $s4, 0($sp)
	jal checkColors   
	addi $sp, $sp, 4    # remove 5th argument on the stack
	li $t8, 0xFFFF
	bne $v0, $t8, main_colors_done
	# print error message
	li $v0, 4
	la $a0, invalid_colorSet_str
	syscall
	j main_enterColors

main_colors_done:
	# save colors
	move $s0, $v0   # CColor curColor
	move $s1, $v1   # err_bg	
main_loadgame:
	li $v0, 4
	la $a0, main_filename_str 
	syscall

	addi $sp, $sp, -48 # create filename buffer
	move $a0, $sp
	li $a1, 48
	li $v0, 8
	syscall
	move $a0, $sp # replace '\n' with '\0'
	jal __replaceNewline

	move $a0, $sp
    move $a1, $s0
	jal readFile
	bltz $v0, main_loadgame_error
	addi $sp, $sp, 48  # remove filename buffer

	li $s2, 81		 # total cells in the board
	sub $s2, $s2, $v0   # remaining cells to fill = total cells in board - unique filled cells
	
	addi $sp, $sp, -8 # create move buffer

	li $s3, 0    # numConflicts to 0
main_move_loop:
	beqz $s2, main_game_won	

	# Prompt player to enter move
	li $v0, 4
	la $a0, enter_move_str
	syscall	

	# Take user input for move
	move $a0, $sp
	li $a1, 48
	li $v0, 8
	syscall
		
	lb $t0, 0($sp) # get first char of string
	beq $t0, 'R', main_make_move_reset
	beq $t0, 'Q', main_quit
#	beq $t0, 'S', main_saveGame
#   beq $t0, 'H', main_hint

	j main_make_move

############################################
# Extra Credit - Save Game
# To use, uncomment this section and line 150 and the appropriate string in the .data section (comment out line 10)
# main_saveGame:
#
#	li $v0, 4
#	la $a0, main_save_str
#	syscall
#
#	addi $sp, $sp, -48 # create filename buffer
#	move $a0, $sp
#	li $a1, 48
#	li $v0, 8
#	syscall
#	move $a0, $sp # replace '\n' with '\0'
#	jal __replaceNewline
#
#	move $a0, $sp   # filename
#   move $a1, $s0   # curColor
#	jal saveBoard
#   bltz $v0, main_saveBoard_err
#	addi $sp, $sp, 48
#
#	li $v0, 4
#	la $a0, main_save_game_str
#	syscall	
#
#    j main_move_loop
#
#main_saveBoard_err:
#
#	li $v0, 4
#	la $a0, main_save_error_str
#	syscall
#   j main_move_loop
############################################

############################################
# Extra Credit - Hint
# To use, uncomment this section and line 151 and the appropriate string in the .data section (comment out line 10)
#main_hint:
#	li $v0, 4
#	la $a0, main_hint_str 
#	syscall
#
#	# Take user input for move
#	move $a0, $sp
#	li $a1, 48
#	li $v0, 8
#	syscall
#
#    move $a0, $sp  # move string
#    move $a1, $s0  # curColor
#	jal hint
#    move $t1, $v0  # save the bit vector
#
#	li $v0, 4
#	la $a0, main_hint_response
#	syscall   
#
#	srl $t1, $t1, 1  # drop off the 0 bit
#  li $t2, 1
#main_print_hint:
#   beq $t2, 10, main_print_hint_done
#   
#   andi $t3, $t1, 0x1   # get LSB
#   beqz $t3, main_print_hint_noprint   # skip value  
#   li $v0, 1
#   move $a0, $t2
#   syscall
#   li $v0, 11
#   li $a0, ' '
#   syscall
#main_print_hint_noprint:
#   addi $t2, $t2, 1
#	srl $t1, $t1, 1  # drop off the 0 bit
#	j main_print_hint
#main_print_hint_done:
#   li $v0, 11
#   li $a0, '\n'
#   syscall
# 	j main_move_loop
############################################

main_make_move_reset:
	# reset the board - change numConflicts to 0	
	move $a0, $s0	# curColor
	move $a1, $s1	# err_bg
	li $a2, 0       # numConflicts == 0 to reset to preset cells only
	jal reset
	bltz $v0, main_game_error
	move $s3, $0    # reset numConflicts
	j main_move_loop
main_make_move:

	blez $s3, main_noConflict
	# remove conflict cells
	move $a0, $s0	# curColor
	move $a1, $s1	# err_bg
	move $a2, $s3   # numConflicts
	jal reset
	bltz $v0, main_game_error
	move $s3, $0    # reset numConflicts

main_noConflict:
	move $a0, $sp   # move string
	move $a1, $s0	# curColors
	move $a2, $s1	# err_bg
	jal makeMove

	bltz $v0, main_makeMove_error
	
	# Successful move
	beqz $v1, main_move_loop  # make move returned (0,0) - no action
	add  $s2, $v1, $s2        # adjust number of cells left to fill
	
	j main_move_loop

main_makeMove_error:
	beqz $v1, main_makeMove_error_invalidMove  # make move returned (-1,0) - invalid move
	
	move $s3, $v1  # save the conflicts to clear on next move

	# conflicts!
	li $v0, 4
	la $a0, conflicts_str
	syscall

	j main_move_loop
	
main_makeMove_error_invalidMove:
	li $v0, 4
	la $a0, invalid_move_str
	syscall
	
	j main_move_loop

main_game_won:

	############################################
	# Extra Credit - uncomment this section
	# li $a0, 0xE3DA   # Cyan and pint win star! 
	# jal setWinBoard
	############################################

	li $v0, 4
	la $a0, game_won_str
	syscall

main_quit:
	addi $sp, $sp, -8 #  remove move buffer

	# quit game!
	li $v0, 10
	syscall 

main_loadgame_error:
	li $v0, 4
	la $a0, main_filename_error_str
	syscall

	j main_loadgame

main_game_error:
	li $v0, 4
	la $a0, main_game_error_str
	syscall

	j main_quit

