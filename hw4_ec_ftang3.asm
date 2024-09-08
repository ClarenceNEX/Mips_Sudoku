# Your full name
# Netid

.text

##########################################
#  Part #1 Functions
##########################################
setWinBoard:
	# insert code here
	jr $ra

saveBoard:
	# insert code here
	li $v0, 0xF2 # replace this line
	li $v1, 0xF2 # replace this line
	jr $ra

hint:
	# insert code here
    li $v0, 0xAAAA # replace this line
	jr $ra
