.text

getBoardInfo:

getBoardInfo_strlen:
        move $t2, $a0   # t2 is starting address of the string
        li $t1,0        # t1 holds the count
getBoardInfo_strlen__nextCh: lb $t0,($t2)    # get a bye from string
        beqz $t0,getBoardInfo_strlen__strEnd # zero means end of string
        addi $t1,$t1,1  # increment count
        addi $t2,$t2,1  # move pointer one character
        j getBoardInfo_strlen__nextCh        # go round the loop again
getBoardInfo_strlen__strEnd:

    # length of the str is in $t1
    blt $t1, 3, getBoardInfo_err
	
    move $t0, $a0   # copy start of string

    bnez $a1, getBoardInfo_valtype

    lb $v0, 0($a0)   # get & check validity of first char
    blt $v0, '0', getBoardInfo_err
    bgt $v0, '8', getBoardInfo_err

    lb $v1, 1($a0)   # get & check validity of second char
    blt $v1, 'A', getBoardInfo_err
    bgt $v1, 'I', getBoardInfo_err

    addi $v0, $v0, -48  # get the value of the row
    addi $v1, $v1, -65  # get the value of the col
    j getBoardInfo_done

getBoardInfo_valtype:
	blt $t1, 4, getBoardInfo_err

    lb $v0, 2($a0)   # get & check validity of first char
    blt $v0, '0', getBoardInfo_err
    bgt $v0, '9', getBoardInfo_err

    lb $v1, 3($a0)   # get & check validity of second char
    beq $v1, 'G', getBoardInfo_4charval
    beq $v1, 'P', getBoardInfo_4charval
    beq $v1, '\n', getBoardInfo_4charval

getBoardInfo_err:
    li $v0, -1
    li $v1, -1
getBoardInfo_done:
	jr $ra

getBoardInfo_4charval:
    addi $v0, $v0, -48  # get the value of the row

	bne $v1, '\n', getBoardInfo_done
	li $v1, 'G'  # replace '\n' with 'G'
    jr $ra
