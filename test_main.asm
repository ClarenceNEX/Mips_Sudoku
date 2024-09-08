.include "hw4_ftang3.asm"
.include "hw4_ec_ftang3.asm"
.include "hw4_helpers.asm"
.data
v1_str:.asciiz "First return value is "
v2_str: .asciiz "Second return value is "

.text
.globl main
main:
	li $a0, 2
	li $a1, 1
	li $a2, 4
	li $a3, 0xA0
	
	jal setCell
	
	li $a0, 0
	li $a1, 0
	jal getCell
	
