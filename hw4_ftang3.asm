# Fan Tang
# ftang3

.text

##########################################
#  Part #1 Functions
##########################################
checkColors:
	lw $t0, 0($sp) # err_bg
	#err_bg check
	beq $t0, $a0, checkColors_error
	beq $t0, $a1, checkColors_error
	beq $t0, $a2, checkColors_error
	beq $t0, $a3, checkColors_error
	#pc_fg & gc_fg
	beq $a1, $a3, checkColors_error
	#pc_fg & pc_bg
	beq $a1, $a0, checkColors_error
	# pc_bg & gc_fg
	beq $a0, $a3, checkColors_error
	# prepare return value
	li $v0, 0
	add $v0, $v0, $a3
	sll $a2, $a2, 4
	add $v0, $v0, $a2
	sll $a1, $a1, 8
	add $v0, $v0, $a1
	sll $a0, $a0, 12
	add $v0, $v0, $a0
	move $v1, $t0
	# return true
	jr $ra
	
	checkColors_error:
	li $v0, 0xFFFF
	li $v1, 0xFF
	jr $ra
setCell:
	# determine the validity
	li $t0, 9
	bge $a0, $t0, setCell_error
	bge $a1, $t0, setCell_error
	bltz $a0, setCell_error
	bltz $a1, setCell_error
	bgt $a2, $t0, setCell_error
	li $t0, -1
	blt $a2, $t0, setCell_error
	#address for MMIO
	li $t0, 0xffff0000 
	# calculate address of row
	li $t1, 2
	mult $a0, $t1
	mflo $a0
	li $t1, 9
	mult $a0, $t1
	mflo $a0
	# calculate address of column
	li $t1, 2
	mult $a1, $t1
	mflo $a1
	# add the address of row
	add $t0, $t0, $a0
	add $t0, $t0, $a1
	# determine the operation for position (r, c)
	beq $a2, 0, setCell_clear
	beq $a2, -1, setCell_color
	# set the color and content
	addi $a2, $a2, 48
	sb $a2, 0($t0)
	sb $a3, 1($t0)
	li $v0 ,0
	jr $ra
	setCell_clear:
		li $a2, '\0'
		sb $a2, 0($t0)
		sb $a3, 1($t0)
		li $v0 ,0
		jr $ra
	setCell_color:
		sb $a3, 1($t0)
		li $v0 ,0
		jr $ra
	setCell_error:
		li $v0, -1
		jr $ra
getCell:
	# check for validity
	li $t0, 9
	bltz $a0, getCell_error
	bltz $a1, getCell_error
	bge $a0, $t0, getCell_error
	bge $a1, $t0, getCell_error
	# calculate row address
	li $t0, 2
	mult $a0, $t0
	mflo $a0
	li $t0, 9
	mult $a0, $t0
	mflo $a0
	# calculate column address
	li $t0, 2
	mult $a1, $t0
	mflo $a1
	# add address
	li $t0, 0xffff0000
	add $t0, $a0, $t0
	add $t0, $a1, $t0
	lb $v0, 1($t0)
	sll $v0, $v0, 24
	srl $v0, $v0, 24
	lb $v1, 0($t0)
	# check the value
	li $t1, '\0'
	beq $t1, $v1, getCell_isnull
	li $t1, 49
	blt $v1, $t1, getCell_error
	li $t1, 57
	bgt $v1, $t1, getCell_error
	addi $v1, $v1, -48
	jr $ra
	getCell_isnull:
		li $v1, 0
		jr $ra
	getCell_error:
		li $v0, 0xff
		li $v1, -1
		jr $ra

reset:
	# pre
	addi $sp, $sp, -40
	sw $ra, 0($sp)
	sw $a0, 4($sp)
	sw $a1, 8($sp)
	sw $a2, 12($sp)
	sw $s0, 16($sp)
	sw $s1, 20($sp)
	sw $s2, 24($sp)
	sw $s3, 28($sp)
	# error check for err_bg > 0xF
	li $t0, 0xF
	bgt $a1, $t0, reset_error
	# determine numconflicts
	bltz $a2, reset_less
	beqz $a2, reset_equal
	bgtz $a2, reset_greater
	reset_less:
		#color & content
		li $s0, 0 # content
		li $s1, 0
		addi $s1, $s1, 240 #color
		#control
		li $s3, 0 # col
		reset_less_for_column:
			li $s2, 0 # row
			reset_less_for_row:
				# set cell
				move $a0, $s2
				move $a1, $s3
				move $a2, $s0
				move $a3, $s1
				jal setCell
				addi $s2, $s2, 1
				li $t5, 9
				blt $s2, $t5, reset_less_for_row
			addi $s3, $s3, 1
			li $t5, 9
			blt $s3, $t5, reset_less_for_column
		#finish
		li $v0, 0
		lw $ra, 0($sp)
		lw $s0, 16($sp)
		lw $s1, 20($sp)
		lw $s2, 24($sp)
		lw $s3, 28($sp)
		addi $sp, $sp, 40
		jr $ra
	reset_equal:
		# control
		li $s0, 0 # col
		reset_equal_for_column:
			li $s1, 0 # row
			reset_equal_for_row:
				# check color
				move $a0, $s1
				move $a1, $s0
				jal getCell
				lw $t0, 4($sp)
				sll $t0, $t0, 16
				srl $t0, $t0, 24
				bne $v0, $t0, reset_equal_set
				reset_equal_continue:
				addi $s1, $s1, 1
				li $t0, 9
				blt $s1, $t0, reset_equal_for_row
			addi $s0, $s0, 1
			li $t0, 9
			blt $s0, $t0, reset_equal_for_column
		#finish
		li $v0, 0
		lw $ra, 0($sp)
		lw $s0, 16($sp)
		lw $s1, 20($sp)
		lw $s2, 24($sp)
		lw $s3, 28($sp)
		addi $sp, $sp, 40
		jr $ra
		reset_equal_set:
			lw $t0, 4($sp)
			sll $t0, $t0, 24
			srl $t0, $t0, 24
			move $a0, $s1
			move $a1, $s0
			li $a2, '\0'
			move $a3, $t0
			jal setCell
			j reset_equal_continue
	reset_greater:
		# control
		# col
		lw $s2, 12($sp)
		li $s0, 0
		reset_greater_for_col:
			# row
			li $s1, 0
			reset_greater_for_row:
				move $a0, $s1
				move $a1, $s0
				jal getCell
				sll $v0, $v0, 28
				srl $v0, $v0, 28
				lw $t0, 4($sp) # preset
				lw $t1, 4($sp) # game cell
				sll $t0, $t0, 20
				srl $t0, $t0, 28
				sll $t1, $t1, 28
				srl $t1, $t1, 28
				beq $v0, $t0, reset_greater_preset
				beq $v0, $t1, reset_greater_gamecell
				j reset_error
				reset_greater_continue:
				beqz $s2, reset_greater_finish
				addi $s1, $s1, 1
				li $t0, 9
				blt $s1, $t0, reset_greater_for_row
			addi $s0, $s0, 1
			li $t0, 9
			blt $s0, $t0, reset_greater_for_col
			bnez $s2, reset_error
			reset_greater_finish:
			li $v0, 0
			lw $ra, 0($sp)
			lw $s0, 16($sp)
			lw $s1, 20($sp)
			lw $s2, 24($sp)
			lw $s3, 28($sp)
			addi $sp, $sp, 40
			jr $ra
		reset_greater_preset:
			move $a0, $s1
			move $a1, $s0
			jal getCell
			sll $v0, $v0, 24
			srl $v0, $v0, 28
			lw $t0, 8($sp)
			bne $v0, $t0, reset_greater_continue
			move $a0, $s1
			move $a1, $s0
			move $a2, $v1
			lw $a3, 4($sp)
			sll $a3, $a3, 16
			srl $a3, $a3, 24
			jal setCell
			addi $s2, $s2, -1
			j reset_greater_continue 
		reset_greater_gamecell:
			move $a0, $s1
			move $a1, $s0
			jal getCell
			sll $v0, $v0, 24
			srl $v0, $v0, 28
			lw $t0, 8($sp)
			bne $v0, $t0, reset_greater_continue
			move $a0, $s1
			move $a1, $s0
			move $a2, $v1
			lw $a3, 4($sp)
			sll $a3, $a3, 24
			srl $a3, $a3, 24
			jal setCell
			addi $s2, $s2, -1
			j reset_greater_continue 
	reset_error:
	li $v0, -1
	lw $ra, 0($sp)
	lw $s0, 16($sp)
	lw $s1, 20($sp)
	lw $s2, 24($sp)
	lw $s3, 28($sp)
	addi $sp, $sp, 40
	jr $ra

##########################################
#  Part #2 Function
##########################################

readFile:
	# pre
	addi $sp, $sp, -60
	sw $ra, 0($sp)
	sw $a0, 4($sp) # filename
	sw $a1, 8($sp) # ccolor
	sw $s0, 12($sp)
	sw $s1, 16($sp)
	sw $s2, 20($sp)
	sw $s3, 24($sp)
	sw $s4, 28($sp)
	# reset
	move $a0, $a1
	li $a1, 0x9
	li $a3, -1
	jal reset
	# open file
	lw $a0, 4($sp)
	li $a1, 0
	li $a2, 0
	li $v0, 13
	syscall
	bltz $v0, readFile_error
	move $s0, $v0 # file descriptor
	# read line
	readFile_for_line:
		move $a0, $s0
		addi $a1, $sp, 52
		li $a2, 5
		li $v0, 14
		syscall
		beqz $v0, readFile_finish
		bltz $v0, readFile_error
		# find position
		addi $a0, $sp, 52
		li $a1, 0
		jal getBoardInfo
		bltz $v0, readFile_error
		move $s1, $v0 # row
		move $s2, $v1 # col
		# find value and type
		addi $a0, $sp, 52
		li $a1, 1
		jal getBoardInfo
		bltz $v0, readFile_error
		move $s3, $v0 # value
		move $s4, $v1 # type
		li $t0, 80
		beq $t0, $s4, readFile_preset
		# is game cell
		lw $a3, 8($sp)
		sll $a3, $a3, 24
		srl $a3, $a3, 24
		move $a0, $s1
		move $a1, $s2
		move $a2, $s3
		jal setCell
		readFile_for_continue:
			j readFile_for_line
		readFile_preset:
			lw $a3, 8($sp)
			sll $a3, $a3, 16
			srl $a3, $a3, 24
			move $a0, $s1
			move $a1, $s2
			move $a2, $s3
			jal setCell
			j readFile_for_continue
		readFile_finish:
			#close file
			move $a0, $s0
			li $v0, 16
			syscall
			# find unique
			li $s2, 0 # counter
			# control
			# row
			li $s0, 0
			readFile_for_row:
				# col
				li $s1, 0
				readFile_for_col:
					move $a0, $s0
					move $a1, $s1
					jal getCell
					li $t0, '\0'
					beq $v1, $t0, readFile_notunique
					addi $s2, $s2, 1
					readFile_notunique_continue:
					addi $s1, $s1, 1
					li $t0, 9
					blt $s1, $t0, readFile_for_col
				addi $s0, $s0, 1
				li $t0, 9
				blt $s0, $t0, readFile_for_row
				# finish
				lw $ra, 0($sp)
				move $v0, $s2
				lw $s0, 12($sp)
				lw $s1, 16($sp)
				lw $s2, 20($sp)
				lw $s3, 24($sp)
				lw $s4, 28($sp)
				addi $sp, $sp, 60
				jr $ra
				readFile_notunique:
					li $t0, 0xffff0000 
					# calculate address of row
					li $t1, 2
					move $t4, $s0
					mult $t4, $t1
					mflo $t4
					li $t1, 9
					mult $t4, $t1
					mflo $t4
					# calculate address of column
					move $t5, $s1
					li $t1, 2
					mult $t5, $t1
					mflo $t5
					# add the address of row
					add $t0, $t0, $t4
					add $t0, $t0, $t5
					sb $0, 0($t0)
					li $t1, 240
					sb $t1, 1($t0)
					j readFile_notunique_continue
		readFile_error:
			lw $ra, 0($sp)
			li $v0, -1
			lw $s0, 12($sp)
			lw $s1, 16($sp)
			lw $s2, 20($sp)
			lw $s3, 24($sp)
			lw $s4, 28($sp)
			addi $sp, $sp, 60
			jr $ra
		
		
##########################################
#  Part #3 Functions
##########################################

rowColCheck:
	# pre
	addi $sp, $sp, -40
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	sw $s2, 12($sp)
	sw $s3, 16($sp)
	move $s0, $a0 # row
	move $s1, $a1 # col
	move $s2, $a2 # value
	# check validity
	li $t0, 9
	bge $a0, $t0, rowColCheck_error
	bge $a1, $t0, rowColCheck_error
	bltz $a0, rowColCheck_error
	bltz $a1, rowColCheck_error
	bgt $a2, $t0, rowColCheck_error
	li $t0, -1
	blt $a2, $t0, rowColCheck_error
	# counter
	li $s3, 0
	# determine col or row
	beqz $a3, rowColCheck_for_row
	rowColCheck_for_col:
		beq $s3, $s1, rowColCheck_for_col_iscell
		move $a0, $s0
		move $a1, $s3
		jal getCell
		beq $v1, $s2, rowColCheck_havesimilar_col
		rowColCheck_for_col_iscell_continue:
		addi $s3, $s3, 1
		li $t0, 9
		blt $s3, $t0, rowColCheck_for_col
		j rowColCheck_finish
	rowColCheck_for_row:
		beq $s3, $s1, rowColCheck_for_row_iscell
		move $a0, $s3
		move $a1, $s1
		jal getCell
		beq $v1, $s2, rowColCheck_havesimilar_row
		rowColCheck_for_row_iscell_continue:
		addi $s3, $s3, 1
		li $t0, 9
		blt $s3, $t0, rowColCheck_for_row
		j rowColCheck_finish
	rowColCheck_finish:
		lw $ra, 0($sp)
		lw $s0, 4($sp)
		lw $s1, 8($sp)
		lw $s2, 12($sp)
		lw $s3, 16($sp)
		li $v0, -1
		li $v1, -1
		addi $sp, $sp, 40
		jr $ra
	rowColCheck_havesimilar_row:
		move $v0, $s0
		move $v1, $s3
		lw $ra, 0($sp)
		lw $s0, 4($sp)
		lw $s1, 8($sp)
		lw $s2, 12($sp)
		lw $s3, 16($sp)
		addi $sp, $sp, 40
		jr $ra
	rowColCheck_havesimilar_col:
		move $v0, $s3
		move $v1, $s1
		lw $ra, 0($sp)
		lw $s0, 4($sp)
		lw $s1, 8($sp)
		lw $s2, 12($sp)
		lw $s3, 16($sp)
		addi $sp, $sp, 40
		jr $ra
	rowColCheck_for_row_iscell:
		j rowColCheck_for_row_iscell_continue
	rowColCheck_for_col_iscell:
		j rowColCheck_for_col_iscell_continue
	rowColCheck_error:
		lw $ra, 0($sp)
		lw $s0, 4($sp)
		lw $s1, 8($sp)
		lw $s2, 12($sp)
		lw $s3, 16($sp)
		li $v0, -1
		li $v1, -1
		addi $sp, $sp, 40
		jr $ra

squareCheck:
	# pre
	addi $sp, $sp, -40
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	sw $s2, 12($sp)
	sw $s3, 16($sp)
	sw $s4, 20($sp)
	sw $a0, 24($sp)
	sw $a1, 28($sp)
	sw $s2, 32($sp)
	move $s0, $a0 # row
	move $s1, $a1 # col
	move $s2, $a2 # value
	# check validity
	li $t0, 9
	bge $a0, $t0, square_check_finish
	bge $a1, $t0, square_check_finish
	bltz $a0, square_check_finish
	bltz $a1, square_check_finish
	bgt $a2, $t0, square_check_finish
	li $t0, -1
	blt $a2, $t0, square_check_finish
	# determine row
	li $t0, 3
	div $s0, $t0
	mflo $s0
	mult $s0, $t0
	mflo $s0
	mult $s1, $t0
	mflo $s1
	# check
	li $s3, 0 # row counter
	squareCheck_for_row:
		li $s4, 0 # col counter
		# determine col
		lw $s1, 28($sp)
		li $t0, 3
		div $s1, $t0
		mflo $s1
		mult $s1, $t0
		mflo $s1
		squareCheck_for_col:
			lw $t0, 24($sp)
			beq $t0, $s0, squareCheck_similar_row
			move $a0, $s0
			move $a1, $s1
			jal getCell
			beq $v1, $s2, squareCheck_havesimilar
			addi $s4, $s4, 1
			addi $s1, $s1, 1
			li $t0, 3
			blt $s4, $t0, squareCheck_for_col
		addi $s3, $s3, 1
		addi $s0, $s0, 1
		li $t0, 3
		blt $s3, $t0, squareCheck_for_row
		j square_check_finish
		squareCheck_similar_row:
			lw $t0, 28($sp)
			beq $t0, $s1, squareCheck_similarcell
			move $a0, $s0
			move $a1, $s1
			jal getCell
			beq $v1, $s2, squareCheck_havesimilar
			squareCheck_similar_row_continue:
			addi $s4, $s4, 1
			addi $s1, $s1, 1
			li $t0, 3
			blt $s4, $t0, squareCheck_similar_row
		addi $s3, $s3, 1
		addi $s0, $s0, 1
		li $t0, 3
		blt $s3, $t0, squareCheck_for_row
		j square_check_finish
		
		squareCheck_havesimilar:
			move $v0, $s0
			move $v1, $s1
			lw $ra, 0($sp)
			lw $s0, 4($sp)
			lw $s1, 8($sp)
			lw $s2, 12($sp)
			lw $s3, 16($sp)
			lw $s4, 20($sp)
			addi $sp, $sp, 40
			jr $ra
		square_check_finish:
			li $v0, -1
			li $v1, -1
			lw $ra, 0($sp)
			lw $s0, 4($sp)
			lw $s1, 8($sp)
			lw $s2, 12($sp)
			lw $s3, 16($sp)
			lw $s4, 20($sp)
			addi $sp, $sp, 40
			jr $ra
		squareCheck_similarcell:
			j squareCheck_similar_row_continue
check:
	# pre
	lw $t0, 0($sp)
	addi $sp, $sp, -40
	sw $ra, 0($sp)
	sw $a0, 4($sp) # row
	sw $a1, 8($sp) # col
	sw $a2, 12($sp) # value
	sw $a3, 16($sp) # err_color
	sw $t0, 20($sp) # flag
	sw $s0, 24($sp)
	sw $s1, 28($sp)
	sw $s2, 32($sp)
	# error check
	li $t0, 9
	bge $a0, $t0, check_error
	bge $a1, $t0, check_error
	bltz $a0, check_error
	bltz $a1, check_error
	bgt $a2, $t0, check_error
	li $t0, -1
	blt $a2, $t0, check_error
	li $t0, 0xF
	bgt $a3, $t0, check_error
	li $s0, 0 # counter
	#flag check
	lw $t0, 20($sp)
	li $t1, 1
	beq $t0, $t1, check_modify
	# check for row
	lw $a0, 4($sp)
	lw $a1, 8($sp)
	lw $a2, 12($sp)
	li $a3, 0
	jal rowColCheck
	li $t0, -1
	beq $v0, $t0, check_unmodify_nrow
	addi $s0, $s0, 1
	check_unmodify_col:
	lw $a0, 4($sp)
	lw $a1, 8($sp)
	lw $a2, 12($sp)
	li $a3, 1
	jal rowColCheck
	li $t0, -1
	beq $v0, $t0, check_unmodify_ncol
	addi $s0, $s0, 1
	check_unmodify_squ:
	lw $a0, 4($sp)
	lw $a1, 8($sp)
	lw $a2, 12($sp)
	jal squareCheck
	li $t0, -1
	beq $v0, $t0, check_unmodify_nsqu
	addi $s0, $s0, 1
	
	check_finish:
		move $v0, $s0
		lw $ra, 0($sp)
		lw $s0, 24($sp)
		lw $s1, 28($sp)
		lw $s2, 32($sp)
		addi $sp, $sp, 40
		jr $ra
	
	check_unmodify_nrow:
		j check_unmodify_col
	check_unmodify_ncol:
		j check_unmodify_squ
	check_unmodify_nsqu:
		j check_finish
	check_error:
		li $v0, -1
		lw $ra, 0($sp)
		lw $s0, 24($sp)
		lw $s1, 28($sp)
		lw $s2, 32($sp)
		addi $sp, $sp, 40
		jr $ra
	check_modify:
	# check for row
	lw $a0, 4($sp)
	lw $a1, 8($sp)
	lw $a2, 12($sp)
	li $a3, 0
	jal rowColCheck
	li $t0, -1
	beq $v0, $t0, check_modify_nrow
	addi $s0, $s0, 1
	move $s1, $v0 # row
	move $s2, $v1 # col
	# get color
	move $a0, $s1
	move $a1, $s2
	jal getCell
	# change back color
	sll $v0, $v0, 28
	srl $v0, $v0, 28
	lw $t0, 16($sp)
	sll $t0, $t0, 4
	add $v0, $v0, $t0
	move $a0, $s1
	move $a1, $s2
	lw $a2, 12($sp)
	move $a3, $v0
	jal setCell
	check_modify_col:
	lw $a0, 4($sp)
	lw $a1, 8($sp)
	lw $a2, 12($sp)
	li $a3, 1
	jal rowColCheck
	li $t0, -1
	beq $v0, $t0, check_modify_ncol
	addi $s0, $s0, 1
	move $s1, $v0 # row
	move $s2, $v1 # col
	# get color
	move $a0, $s1
	move $a1, $s2
	jal getCell
	# change back color
	sll $v0, $v0, 28
	srl $v0, $v0, 28
	lw $t0, 16($sp)
	sll $t0, $t0, 4
	add $v0, $v0, $t0
	move $a0, $s1
	move $a1, $s2
	lw $a2, 12($sp)
	move $a3, $v0
	jal setCell
	check_modify_squ:
	lw $a0, 4($sp)
	lw $a1, 8($sp)
	lw $a2, 12($sp)
	jal squareCheck
	li $t0, -1
	beq $v0, $t0, check_modify_nsqu
	addi $s0, $s0, 1
	move $s1, $v0 # row
	move $s2, $v1 # col
	# get color
	move $a0, $s1
	move $a1, $s2
	jal getCell
	# change back color
	sll $v0, $v0, 28
	srl $v0, $v0, 28
	lw $t0, 16($sp)
	sll $t0, $t0, 4
	add $v0, $v0, $t0
	move $a0, $s1
	move $a1, $s2
	lw $a2, 12($sp)
	move $a3, $v0
	jal setCell
	j check_finish
	check_modify_nrow:
		j check_modify_col
	check_modify_ncol:
		j check_modify_squ
	check_modify_nsqu:
		j check_finish

makeMove:
	# pre
	addi $sp, $sp, -80
	sw $ra, 76($sp)
	sw $a0, 4($sp)
	sw $a1, 8($sp)
	sw $a2, 12($sp)
	# Decipher the move string
	lw $a0, 4($sp)
	li $a1, 0
	jal getBoardInfo
	sw $v0, 16($sp) # row
	sw $v1, 20($sp) # col
	li $t0, -1
	beq $t0, $v0, makeMove_error
	lw $a0, 4($sp)
	li $a1, 1
	jal getBoardInfo
	sw $v0, 24($sp) # moveValue
	sw $v1, 28($sp) # type
	li $t0, -1
	beq $t0, $v0, makeMove_error
	lw $a0, 16($sp)
	lw $a1, 20($sp)
	jal getCell
	sw $v0, 32($sp) # cellColor
	sw $v1, 36($sp) # curvalue
	lw $t0, 24($sp)
	beq $v1, $t0, makeMove_inboard
	li $t0, '\0'
	beq $v1, $t0, makeMove_inboard_check
	makeMove_inboard_check_continue:
	lw $t0, 8($sp)
	srl $t0, $t0, 8
	lw $t1, 32($sp)
	beq $t0, $t1, makeMove_error
	lw $t0, 24($sp)
	li $t1, 0
	beq $t0, $t1, makeMove_emptycell
	# check conflict
	lw $a0, 16($sp)
	lw $a1, 20($sp)
	lw $a2, 24($sp)
	lw $a3, 12($sp)
	li $t0, 1
	sw $t0, 0($sp)
	jal check
	sw $v0, 40($sp) # conflict
	bnez $v0, makeMove_haveconflict
	lw $a0, 16($sp)
	lw $a1, 20($sp)
	lw $a2, 24($sp)
	lw $a3, 8($sp)
	sll $a3, $a3, 24
	srl $a3, $a3, 24
	jal setCell
	li $v0, 0
	li $v1, -1
	lw $ra, 76($sp)
	addi $sp, $sp, 80
	jr $ra
	
	makeMove_haveconflict:
	li $v0, -1
	lw $v1, 40($sp)
	lw $ra, 76($sp)
	addi $sp, $sp, 80
	jr $ra
	
	makeMove_emptycell:
	lw $a0, 16($sp)
	lw $a1, 20($sp)
	li $a2, 0
	lw $a3, 8($sp)
	sll $a3, $a3, 24
	srl $a3, $a3, 24
	jal setCell
	li $v0, 0
	li $v1, 1
	lw $ra, 76($sp)
	addi $sp, $sp, 80
	jr $ra
		
	
	makeMove_inboard_check:
	li $t0, 0
	lw $t1, 24($sp)
	beq $t0, $t1, makeMove_inboard
	j makeMove_inboard_check_continue
	
	makeMove_inboard:
	li $v0, 0
	li $v1, 0
	lw $ra, 76($sp)
	addi $sp, $sp, 80
	jr $ra
	
	makeMove_error:
	li $v0, -1
	li $v1, 0
	lw $ra, 76($sp)
	addi $sp, $sp, 80
	jr $ra
