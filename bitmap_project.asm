#Brandon Atwal BSA190001 
#Bitmap Project CS2340.0W3
# Instructions: 
#   Connect bitmap display:
#         set pixel dim to 4x4
#         set display dim to 256x256. 
#	use $gp as base address
#   Connect Bitmap Display and keyboard ("Keyboard and Display MMIO Simulator"), then run
#	use w (up), s (down), a (left), d (right), space (exit)
#	all other keys are ignored
#Prints a String
.macro printString (%str)
.text
	li 	$v0, 4
	la 	$a0, %str
	syscall
.end_macro
# set up some constants
# width of screen in pixels
# 256 / 4 = 64
.eqv WIDTH 64
# height of screen in pixels
.eqv HEIGHT 64

# colors
.eqv	RED 	0x00FF0000
.eqv	REDish	0x00FF2222 #a near-red color that wont mess with color change algorithm
.eqv	GREEN 	0x0000FF00
.eqv	BLUE	0x000000FF
.eqv	WHITE	0x00FFFFFF
.eqv	YELLOW	0x00FFFF00
.eqv	CYAN	0x0000FFFF
.eqv	MAGENTA	0x00FF00FF
.eqv	BLACK	0x00000000

.data
colors:	.word	MAGENTA, CYAN, YELLOW, BLUE, GREEN, WHITE, RED
width:	.word	2	#width of square, starts at 1
gameOverStr:	.asciiz	"Game Over."
#coordinates of dots. f = food, p=poison, m=muck, g=grease
#food is used to grow to the next size
f1X:	.word	0
f1Y:	.word	0
f2X:	.word	0
f2Y:	.word	0
foodTillGrow:	.word	2	#the amount of food to consume until next size up
timesGrown:	.word	0	#the amount of times the blob has grown
#poison shrinks the blob
p1X:	.word	0
p1Y:	.word	0
widthToInsert:	.word	0	#the width to insert. Will be 0 if no width to insert.
#muck slows the blob down
m1X:	.word	0
m1Y:	.word	0
m2X:	.word	0
m2Y:	.word	0
#grease speeds the blob up
g1X:	.word	0
g1Y:	.word	0
waitTime:	.word	6	#the time to wait in milliseconds in between painting pixels. Also used to control blob speed.
				
.text
main:
titleScreen:
	jal	blackAll	#clear anything that may already be on screen
	jal 	printTitle	#paint title screen
titleLoop:
	# check for input
	lw 	$t0, 0xffff0000 	#t1 holds if input available
    	beq 	$t0, 0, titleLoop	#If no input, keep displaying
	
	# process input
	lw 	$s1, 0xffff0004
	beq	$s1, 32, start	# input space
	j	titleLoop
	
start:
	jal 	blackAll	#erase the title screen
	#set up starting position of dots
	jal 	initialRandomize
	lw	$a0, f1X
	lw	$a1, f1Y
	addi 	$a2, $0, BLUE  		# a2 = blue
	jal 	drawPixel
	lw	$a0, f2X
	lw	$a1, f2Y
	jal 	drawPixel
	lw	$a0, p1X
	lw	$a1, p1Y
	addi 	$a2, $0, GREEN  	# a2 = green
	jal 	drawPixel
	lw	$a0, m1X
	lw	$a1, m1Y
	addi 	$a2, $0, MAGENTA  	# a2 = magenta
	jal 	drawPixel
	lw	$a0, m2X
	lw	$a1, m2Y
	addi 	$a2, $0, MAGENTA  	# a2 = magenta
	jal 	drawPixel
	lw	$a0, g1X
	lw	$a1, g1Y
	addi 	$a2, $0, YELLOW  	# a2 = yellow
	jal 	drawPixel
	
	# set up starting position of blob
	addi 	$a0, $0, WIDTH   	# a0 = X = WIDTH/2
	sra 	$a0, $a0, 1
	addi 	$a1, $0, HEIGHT   	# a1 = Y = HEIGHT/2
	sra 	$a1, $a1, 1
	addi 	$a2, $0, RED  		# a2 = red (ox00RRGGBB) - color
	
gameLoop:
drawBlob:
	# prepare for interior loop
	li	$t1, 0			#$t1 = i = 0
	lw	$t2, width		#$t2 = stop value
	
loopHorzR: #horizontal loop, from left to RIGHT
	beq 	$t1, $t2, doneHorzR  	#branch if i == desired width
	addi	$t1, $t1, 1		#i++

	#move pixel 1 to the right
	addi	$a0, $a0, 1
	#change color
	jal	changeColor
	# draw a  pixel 
	jal 	drawPixel
	jal	wait
	
	j	loopHorzR
doneHorzR:

	# prepare for loop
	li	$t1, 0			#$t1 = i = 0
	lw	$t2, width		#$t2 = stop value

loopVertD: #horizontal loop, going DOWNWARDS on the right side
	beq 	$t1, $t2, doneVertD  	#branch if i == desired width
	addi	$t1, $t1, 1		#i++

	#move pixel 1 downwards
	addi	$a1, $a1, 1
	#change color
	jal	changeColor
	# draw a  pixel 
	jal 	drawPixel
	jal	wait
		
	j	loopVertD
doneVertD:

	# prepare for loop
	li	$t1, 0			#$t1 = i = 0
	lw	$t2, width		#$t2 = stop value
	
loopHorzL: #horizontal loop, from right to LEFT
	beq 	$t1, $t2, doneHorzL  	#branch if i == desired width
	addi	$t1, $t1, 1		#i++

	#move pixel 1 to the left
	subi	$a0, $a0, 1
	#change color
	jal	changeColor
	# draw a pixel 
	jal 	drawPixel
	jal	wait	
	
	j	loopHorzL
doneHorzL:

	# prepare for loop
	li	$t1, 0			#$t1 = i = 0
	lw	$t2, width		#$t2 = stop value

loopVertU: #horizontal loop, going UPWARDS on the left side
	beq 	$t1, $t2, doneVertU  	#branch if i == desired width
	addi	$t1, $t1, 1		#i++

	#move pixel 1 upwards
	subi	$a1, $a1, 1
	#change color
	jal	changeColor
	# draw a pixel 
	jal 	drawPixel
	jal	wait	
	
	j	loopVertU
doneVertU:

processDots:
	jal 	checkDots	#check to see if the dots have been touched
	addi	$t0, $a0, 0	#save a0 and a1 and a3; a0 is x
	addi	$t1, $a1, 0	#y
	addi	$t2, $a2, 0	#color
	
	#draw the pixels
	lw	$a0, f1X
	lw	$a1, f1Y
	addi 	$a2, $0, BLUE  		# a2 = blue (ox00RRGGBB) - color
	jal	drawPixel
	
	lw	$a0, f2X
	lw	$a1, f2Y
	addi 	$a2, $0, BLUE  		# a2 = blue (ox00RRGGBB) - color
	jal	drawPixel
	
	lw	$a0, p1X
	lw	$a1, p1Y
	addi 	$a2, $0, GREEN  	# a2 = green (ox00RRGGBB) - color
	jal	drawPixel
	
	lw	$a0, m1X
	lw	$a1, m1Y
	addi 	$a2, $0, MAGENTA  	# a2 = magenta (ox00RRGGBB) - color
	jal	drawPixel
	
	lw	$a0, m2X
	lw	$a1, m2Y
	addi 	$a2, $0, MAGENTA  	# a2 = magenta (ox00RRGGBB) - color
	jal	drawPixel
	
	lw	$a0, g1X
	lw	$a1, g1Y
	addi 	$a2, $0, YELLOW  	# a2 = yellow (ox00RRGGBB) - color
	jal	drawPixel
	
	
	addi	$a0, $t0, 0	#load a0 and a1 and a3; a0 is x
	addi	$a1, $t1, 0	#y
	addi	$a2, $t2, 0	#color
	
pDotsDone:

inputLoop:
	# check for input
	lw 	$t0, 0xffff0000 	#t1 holds if input available
    	beq 	$t0, 0, blobDone	#If no input, keep displaying
	
	# process input
	lw 	$s1, 0xffff0004
	beq	$s1, 32, exit	# input space
	beq	$s1, 119, up 	# input w
	beq	$s1, 115, down 	# input s
	beq	$s1, 97, left  	# input a
	beq	$s1, 100, right	# input d
	# invalid input, ignore
	j	inputLoop
	
up:	jal	eraseBox
	ble	$a1, 0, blobDone	#if Y coordinate is <= 0, dont move upwards
	subi	$a1, $a1, 1		#else, move up
	j	blobDone
	
down:	jal	eraseBox
	lw	$t0, width
	li	$t1, 63
	sub	$t1, $t1, $t0
	bge	$a1, $t1, blobDone	#if Y coordinate is >= (63 - width), dont move downwards
	addi	$a1, $a1, 1		#else, move down
	j	blobDone
	
left:	jal	eraseBox
	ble	$a0, 0, blobDone	#if X coord is <= 0, dont move left
	subi	$a0, $a0, 1		#else, move left
	j	blobDone
	
right:	jal	eraseBox
	lw	$t0, width
	li	$t1, 63
	sub	$t1, $t1, $t0
	bge	$a0, $t1, blobDone	#if X coord is >= (63 - width), dont move right
	addi	$a0, $a0, 1		#else, move right
	j	blobDone
	
blobDone:

processGrowth:	#process whether or not the blob grows
	lw	$t0, foodTillGrow
	bgt	$t0, $0, endGrowth	#if foodTillGrow > 0, end (no growth). Otherwise:
	#increment times grown AND blob width
	jal eraseBox
	lw	$t1, timesGrown
	addi	$t1, $t1, 1
	sw	$t1, timesGrown
	lw	$t1, width
	addi	$t1, $t1, 1
	sw	$t1, width
	#reset foodTillGrow
	beq	$t1, 7, blobSeven  #if blob is now size 7, incremement once more then process as huge blob
	beq	$t1, 14, blobSeven #same with blob at 14
	bgt	$t1, 7, hugeBlob  #if the blob width is over 7, then the blob will take WAY longer to grow
	bgt	$t1, 3, largeBlob #if the blob width is over 3, then the blob will take longer to grow
	addi	$t0, $0, 3
	sw	$t0, foodTillGrow
	j	endGrowth
largeBlob:
	addi	$t0, $0, 5
	sw	$t0, foodTillGrow
	j	endGrowth
blobSeven:
	addi	$t1, $t1, 1	#increment blob width 1 more time to make massive and avoid color issues
hugeBlob:
	sw	$t1, width
	addi	$t0, $0, 8
	sw	$t0, foodTillGrow
	
endGrowth:

processShrink:	#process whether or not the blob shrinks (via poison)
	lw	$t1, widthToInsert
	beq	$t1, 0, endShrink	#if the width to insert is 0, then jump to endShrink (this means the blob will not shrink)
	jal	eraseBox
	lw	$t1, widthToInsert
	sw	$t1, width		#else, insert given width to width (this means the blob did shrink)
	sw	$0, widthToInsert	#make widthToInsert 0 again
endShrink:


gameLoopBottom:
	j	gameLoop

exit: 	
	# clear screen then paint game over screen
	jal	blackAll
	jal 	paintGameOver
	# exit the program
	printString(gameOverStr)
	li	$v0, 10
	syscall
	
####################################################
# draws a pixel
# $a0 = X
# $a1 = Y
# $a2 = color
drawPixel:
	# s1 = address = $gp + 4*(x + y*width)
	mul	$t9, $a1, WIDTH   # y * WIDTH
	add	$t9, $t9, $a0	  # add X
	mul	$t9, $t9, 4	  # multiply by 4 to get word offset
	add	$t9, $t9, $gp	  # add to base address
	sw	$a2, ($t9)	  # store color at memory location
	
	jr 	$ra
####################################################
# check if dots are within the blob
checkDots:
	addi	$t0, $ra, 0	#save $ra

	add	$t3, $0, $a0	#get starting X of blob
	add	$t4, $0, $a1	#get starting Y of blob
	lw	$t7, width	#t0 = current width of blob
	add	$t5, $t7, $t3	#get largest X of blob
	add	$t6, $t7, $t4	#get largest Y of blob
	
CHKf1:	#check f1	
	lw	$t1, f1X
	lw	$t2, f1Y
	blt	$t1, $t3, notf1	#if it's outside the blob, jump
	blt	$t2, $t4, notf1 
	bgt	$t1, $t5, notf1 
	bgt	$t2, $t6, notf1
	#if it got here, it should be within the blob
	lw	$t1, foodTillGrow 	#decrement foodTillGrow
	subi	$t1, $t1, 1
	sw	$t1, foodTillGrow
	jal	randomizeF1		#randomize dot location
notf1:
	
CHKf2:	#check f2		
	lw	$t1, f2X
	lw	$t2, f2Y
	blt	$t1, $t3, notf2	#if it's outside the blob, jump
	blt	$t2, $t4, notf2 
	bgt	$t1, $t5, notf2
	bgt	$t2, $t6, notf2
	#if it got here, it should be within the blob
	lw	$t1, foodTillGrow 	#decrement foodTillGrow
	subi	$t1, $t1, 1
	sw	$t1, foodTillGrow
	jal	randomizeF2		#randomize dot location
notf2:

CHKp1:	#check p1		
	lw	$t1, p1X
	lw	$t2, p1Y
	blt	$t1, $t3, notp1	#if it's outside the blob, jump
	blt	$t2, $t4, notp1 
	bgt	$t1, $t5, notp1
	bgt	$t2, $t6, notp1
	#if it got here, it should be within the blob
	lw	$t1, width 	#decrement width if width > 1
	ble	$t1, 1, exit	#if width <= 1, exit game (GAME OVER)
	subi	$t1, $t1, 1	#otherwise decrement size by 1
	sw	$t1, widthToInsert	#set to widthToInsert so it will not change width until growth is processed
	jal	randomizeP1		#randomize dot location
notp1:

CHKm1:#check m1	 - muck slows the blob down	
	lw	$t1, m1X
	lw	$t2, m1Y
	blt	$t1, $t3, notm1	#if it's outside the blob, jump
	blt	$t2, $t4, notm1 
	bgt	$t1, $t5, notm1
	bgt	$t2, $t6, notm1
	#if it got here, it should be within the blob
	lw	$t1, waitTime
	bge	$t1, 12, m1NoChange	#if waitTime >= 12, dont increment it. This stops it from becoming unreasonably slow
	addi	$t1, $t1, 1		#else increment waitTime
	sw	$t1, waitTime
m1NoChange:
	jal	randomizeM1		#randomize dot location
notm1:

CHKm2:#check m2	 - muck slows the blob down	
	lw	$t1, m2X
	lw	$t2, m2Y
	blt	$t1, $t3, notm2	#if it's outside the blob, jump
	blt	$t2, $t4, notm2 
	bgt	$t1, $t5, notm2
	bgt	$t2, $t6, notm2
	#if it got here, it should be within the blob
	lw	$t1, waitTime
	bge	$t1, 12, m2NoChange	#if waitTime >= 12, dont increment it. This stops it from becoming unreasonably slow
	addi	$t1, $t1, 1		#else increment waitTime
	sw	$t1, waitTime
m2NoChange:
	jal	randomizeM2		#randomize dot location
notm2:

CHKg1:#check g1	 - grease speeds the blob up	
	lw	$t1, g1X
	lw	$t2, g1Y
	blt	$t1, $t3, notg1	#if it's outside the blob, jump
	blt	$t2, $t4, notg1 
	bgt	$t1, $t5, notg1
	bgt	$t2, $t6, notg1
	#if it got here, it should be within the blob
	lw	$t1, waitTime
	ble	$t1, 2, g1NoChange	#if waitTime <= 2, dont decrement it. This stops it from becoming too fast
	addi	$t1, $t1, -1		#else decrement waitTime
	sw	$t1, waitTime
g1NoChange:
	jal	randomizeG1		#randomize dot location
notg1:
			
checkEnd:
	addi	$ra, $t0, 0	#load $ra
	jr	$ra
####################################################
# randomize locations of f1
randomizeF1:
	addi	$t1, $a0, 0	#save a0 and a1
	addi	$t2, $a1, 0
	
	li	$a1, 63
	li	$v0, 42
	syscall
	sw	$a0, f1X
	
	li	$a1, 63
	li	$v0, 42
	syscall
	sw	$a0, f1Y

	addi	$a0, $t1, 0	#retrieve the old a0 and a1
	addi	$a1, $t2, 0
	jr	$ra
####################################################
# randomize locations of f2
randomizeF2:
	addi	$t1, $a0, 0	#save a0 and a1
	addi	$t2, $a1, 0
	
	li	$a1, 63
	li	$v0, 42
	syscall
	sw	$a0, f2X
	
	li	$a1, 63
	li	$v0, 42
	syscall
	sw	$a0, f2Y

	addi	$a0, $t1, 0	#retrieve the old a0 and a1
	addi	$a1, $t2, 0
	jr	$ra
####################################################
# randomize locations of p1
randomizeP1:
	addi	$t1, $a0, 0	#save a0 and a1
	addi	$t2, $a1, 0
	
	li	$a1, 63
	li	$v0, 42
	syscall
	sw	$a0, p1X
	
	li	$a1, 63
	li	$v0, 42
	syscall
	sw	$a0, p1Y

	addi	$a0, $t1, 0	#retrieve the old a0 and a1
	addi	$a1, $t2, 0
	jr	$ra
####################################################
# randomize locations of m1
randomizeM1:
	addi	$t1, $a0, 0	#save a0 and a1
	addi	$t2, $a1, 0
	
	li	$a1, 63
	li	$v0, 42
	syscall
	sw	$a0, m1X
	
	li	$a1, 63
	li	$v0, 42
	syscall
	sw	$a0, m1Y

	addi	$a0, $t1, 0	#retrieve the old a0 and a1
	addi	$a1, $t2, 0
	jr	$ra
####################################################
# randomize locations of m2
randomizeM2:
	addi	$t1, $a0, 0	#save a0 and a1
	addi	$t2, $a1, 0
	
	li	$a1, 63
	li	$v0, 42
	syscall
	sw	$a0, m2X
	
	li	$a1, 63
	li	$v0, 42
	syscall
	sw	$a0, m2Y

	addi	$a0, $t1, 0	#retrieve the old a0 and a1
	addi	$a1, $t2, 0
	jr	$ra
####################################################
# randomize locations of g1
randomizeG1:
	addi	$t1, $a0, 0	#save a0 and a1
	addi	$t2, $a1, 0
	
	li	$a1, 63
	li	$v0, 42
	syscall
	sw	$a0, g1X
	
	li	$a1, 63
	li	$v0, 42
	syscall
	sw	$a0, g1Y

	addi	$a0, $t1, 0	#retrieve the old a0 and a1
	addi	$a1, $t2, 0
	jr	$ra
####################################################
# randomize locations the initial time, before the rest of the program begins
initialRandomize:
	#food 1
	li	$a1, 63
	li	$v0, 42
	syscall
	sw	$a0, f1X
	
	li	$a1, 63
	li	$v0, 42
	syscall
	sw	$a0, f1Y
	
	#food 2
	li	$a1, 63
	li	$v0, 42
	syscall
	sw	$a0, f2X
	
	li	$a1, 63
	li	$v0, 42
	syscall
	sw	$a0, f2Y
	
	#poison 1
    	li	$a1, 63
	li	$v0, 42
	syscall
	sw	$a0, p1X
    	
	li	$a1, 63
	li	$v0, 42
	syscall
	sw	$a0, p1Y
	
	#muck 1
    	li	$a1, 63
	li	$v0, 42
	syscall
	sw	$a0, m1X
    	
	li	$a1, 63
	li	$v0, 42
	syscall
	sw	$a0, m1Y
	
	#muck 2
    	li	$a1, 63
	li	$v0, 42
	syscall
	sw	$a0, m2X
    	
	li	$a1, 63
	li	$v0, 42
	syscall
	sw	$a0, m2Y
    	
	#grease 1
    	li	$a1, 63
	li	$v0, 42
	syscall
	sw	$a0, g1X
    	
	li	$a1, 63
	li	$v0, 42
	syscall
	sw	$a0, g1Y
    	
    	#clear a0 and a1
    	addi	$a1, $0, 0
    	addi	$a0, $0, 0
	
	jr	$ra

####################################################
# Waits for waitTime ms
wait:
	lw	$t6, waitTime	#time to wait in milliseconds
	add	$t7, $0, $a0	#save a0
	# delay - waitTime ms
	li	$v0, 32		#sleep/delay
	add	$a0, $0, $t6	#t6 holds time in milliseconds
	syscall
	add	$a0, $0, $t7	#return original a0 value
	jr	$ra

####################################################
# changes the color
# $s3 = i
# $s6 = base of colors array
# temps used: $t3, $t4
# $a2 = color of pixel
#If the current color is red, it will jump to isRed and change the color to the 1st one in the array (magenta)
#otherwise it will loop through the array until the same current color is found in the array
#it will then take i and use it as the offset from the base address, and use that to find
#the next element of the array.
changeColor:
	li	$s3, 0		#s3 = i = 0
	la	$s6, colors	#s6 = base of colors array
	li	$s5, RED	#$s5 = red, the final item in the array
	beq	$a2, $s5, isRed
loopNotRed:
	sll	$t3, $s3, 2	#i = i*4
	add	$t3, $t3, $s6	#address = i*4 + arr[0]
	lw	$t4, ($t3)	#get next array element
	beq	$t4, $a2, endNotRed
	addi	$s3, $s3, 1	#i++
	j	loopNotRed
endNotRed:
	addi	$s3, $s3, 1
	sll	$t3, $s3, 2	#i = i*4
	add	$t3, $t3, $s6	#address = i*4 + arr[0]
	lw	$t4, ($t3)	#get next color
	add	$a2, $0, $t4
	j	endChangeColor
isRed:	
	lw	$t3, ($s6)	#get first array element
	add 	$a2, $0, $t3 	# a2 = base color
endChangeColor:
	jr	$ra
	
####################################################
#erases the old box by putting black pixels over it
#t6 = temporary storage for old color
#t7 = temp storage for old return address
#a2 = color of pixel, a0=x a1=y
#t1, t2 = control temps
eraseBox:
	add	$t6, $0, $a2		#save old color
	addi 	$a2, $0, 0		#make color black
	add	$t7, $0, $ra		#save $ra

	# prepare for interior loop
	li	$t1, 0			#$t1 = i = 0
	lw	$t2, width		#$t2 = stop value
	
loopTop: #horizontal loop, from left to RIGHT
	beq 	$t1, $t2, doneTop  	#branch if i == desired width
	addi	$t1, $t1, 1		#i++

	#move pixel 1 to the right
	addi	$a0, $a0, 1
	
	# draw a red  pixel 
	jal 	drawPixel
	
	j	loopTop
doneTop:

	# prepare for loop
	li	$t1, 0			#$t1 = i = 0
	lw	$t2, width		#$t2 = stop value

loopRight: #horizontal loop, going DOWNWARDS on the right side
	beq 	$t1, $t2, doneRight  	#branch if i == desired width
	addi	$t1, $t1, 1		#i++

	#move pixel 1 downwards
	addi	$a1, $a1, 1
	
	# draw a red  pixel 
	jal 	drawPixel
		
	j	loopRight
doneRight:

	# prepare for loop
	li	$t1, 0			#$t1 = i = 0
	lw	$t2, width		#$t2 = stop value
	
loopBot: #horizontal loop, from right to LEFT
	beq 	$t1, $t2, doneBot  	#branch if i == desired width
	addi	$t1, $t1, 1		#i++

	#move pixel 1 to the left
	subi	$a0, $a0, 1
	# draw a red  pixel 
	jal 	drawPixel
	
	j	loopBot
doneBot:

	# prepare for loop
	li	$t1, 0			#$t1 = i = 0
	lw	$t2, width		#$t2 = stop value

loopLeft: #horizontal loop, going UPWARDS on the left side
	beq 	$t1, $t2, doneLeft  	#branch if i == desired width
	addi	$t1, $t1, 1		#i++

	#move pixel 1 upwards
	subi	$a1, $a1, 1
	# draw a red  pixel 
	jal 	drawPixel
	
	j	loopLeft
doneLeft:

endErase:
	add	$a2, $0, $t6		#restore previous color
	add	$ra, $0, $t7 		#restore previous ra
	jr 	$ra
####################################################
#blackens the entire game screen. For use after title screen and game over screen
#t7 = temp storage for old return address
#a2 = color of pixel, a0=x a1=y
#t1, t2 = control temps
blackAll:
	add	$t7, $0, $ra	#save $ra
	addi 	$a0, $0, 0   	# a0 = X 
	addi 	$a1, $0, 0   	# a1 = Y
	addi 	$a2, $0, BLACK 	# a2 = black (ox00RRGGBB) - color
	addi	$t2, $0, WIDTH	#$t2 = key = display width - 1 = display height - 1
	subi	$t2, $t2, 1
loopB1:
	beq	$a1, $t2, breakB1 
loopB2:
	beq	$a0, $t2, breakB2 #since display WIDTH and HEIGHT are the same, we can use t2 for both loops
	jal	drawPixel
	addi	$a0, $a0, 1
	j	loopB2
breakB2:
	addi	$a0, $0, 0
	addi	$a1, $a1, 1
	j	loopB1	
breakB1:
returnBlacken:
	add	$ra, $0, $t7
	jr	$ra
####################################################
#draws the title of the game: Get Fat
#t7 = temp storage for old return address
#a2 = color of pixel, a0=x a1=y
#t1, t2 = control temps
printTitle:
	add	$t7, $0, $ra		#save $ra
	
	# set up starting position of blob
	addi 	$a0, $0, 12   	# a0 = X 
	addi 	$a1, $0, 12   	# a1 = Y
	addi 	$a2, $0, RED  	# a2 = red (ox00RRGGBB) - color

	#DRAW GET	
	# prepare for loop
	li	$t1, 0		#$t1 = i = 0
	li	$t2, 19		#t2=key
Horz1:
	beq	$t1, $t2, BreakH1
	jal	drawPixel
	addi	$a0, $a0, 1	#X++
	addi	$t1, $t1, 1	#i++
	j	Horz1
BreakH1:
	#add black space between letters
	addi 	$a2, $0, BLACK  	# a2 = black (ox00RRGGBB) - color
	subi	$a0, $a0, 7
	jal	drawPixel
	subi	$a0, $a0, 5
	jal	drawPixel
	subi	$a0, $a0, 1
	jal	drawPixel
	
	# prepare for loop
	addi 	$a0, $0, 12   	# a0 = X 
	addi 	$a1, $0, 13   	# a1 = Y
	addi 	$a2, $0, RED  	# a2 = red (ox00RRGGBB) - color
	li	$t1, 0		#$t1 = i = 0
	li	$t2, 8		#t2=key
Vert1:
	beq	$t1, $t2, BreakV1
	jal	drawPixel
	addi	$a1, $a1, 1	#y++
	addi	$t1, $t1, 1	#i++
	j	Vert1
BreakV1:
	# prepare for loop
	addi 	$a0, $0, 20   	# a0 = X 
	addi 	$a1, $0, 13   	# a1 = Y
	li	$t1, 0		#$t1 = i = 0
	li	$t2, 8		#t2=key
Vert2:
	beq	$t1, $t2, BreakV2
	jal	drawPixel
	addi	$a1, $a1, 1	#y++
	addi	$t1, $t1, 1	#i++
	j	Vert2
BreakV2:
	# prepare for loop
	addi 	$a0, $0, 28   	# a0 = X 
	addi 	$a1, $0, 13   	# a1 = Y
	li	$t1, 0		#$t1 = i = 0
	li	$t2, 8		#t2=key
Vert3:
	beq	$t1, $t2, BreakV3
	jal	drawPixel
	addi	$a1, $a1, 1	#y++
	addi	$t1, $t1, 1	#i++
	j	Vert3
BreakV3:
	# prepare for loop
	addi 	$a0, $0, 17   	# a0 = X 
	addi 	$a1, $0, 17   	# a1 = Y
	li	$t1, 0		#$t1 = i = 0
	li	$t2, 4		#t2=key
Vert4:
	beq	$t1, $t2, BreakV4
	jal	drawPixel
	addi	$a1, $a1, 1	#y++
	addi	$t1, $t1, 1	#i++
	j	Vert4
BreakV4:
	# prepare for loop
	addi 	$a0, $0, 12   	# a0 = X 
	addi 	$a1, $0, 20   	# a1 = Y
	li	$t1, 0		#$t1 = i = 0
	li	$t2, 5		#t2=key
Horz2:
	beq	$t1, $t2, BreakH2
	jal	drawPixel
	addi	$a0, $a0, 1	#x++
	addi	$t1, $t1, 1	#i++
	j	Horz2
BreakH2:
	#interior of G
	addi 	$a0, $0, 16   	# a0 = X 
	addi 	$a1, $0, 17   	# a1 = Y
	jal	drawPixel
	addi 	$a0, $0, 15   	# a0 = X 
	jal	drawPixel

	# prepare for loop
	addi 	$a0, $0, 21   	# a0 = X 
	addi 	$a1, $0, 16   	# a1 = Y
	li	$t1, 0		#$t1 = i = 0
	li	$t2, 4		#t2=key
Horz3:
	beq	$t1, $t2, BreakH3
	jal	drawPixel
	addi	$a0, $a0, 1	#x++
	addi	$t1, $t1, 1	#i++
	j	Horz3
BreakH3:
	# prepare for loop
	addi 	$a0, $0, 21   	# a0 = X 
	addi 	$a1, $0, 20   	# a1 = Y
	li	$t1, 0		#$t1 = i = 0
	li	$t2, 4		#t2=key
Horz4:
	beq	$t1, $t2, BreakH4
	jal	drawPixel
	addi	$a0, $a0, 1	#x++
	addi	$t1, $t1, 1	#i++
	j	Horz4
BreakH4:

	####Draw FAT
	# prepare for loop
	addi 	$a1, $0, 28   	# a1 = Y
HGroup1:
	addi 	$a0, $0, 6   	# a0 = X 
	li	$t1, 0		#$t1 = i = 0
	li	$t2, 14		#t2=key
fatH1:	
	beq	$t1, $t2, breakFH1
	jal	drawPixel
	addi	$a0, $a0, 1	#x++
	addi	$t1, $t1, 1	#i++
	j	fatH1
breakFH1:
	# prepare for loop
	addi 	$a0, $0, 24   	# a0 = X 
	li	$t1, 0		#$t1 = i = 0
	li	$t2, 24		#t2=key
fatH2:	
	beq	$t1, $t2, breakFH2
	jal	drawPixel
	addi	$a0, $a0, 1	#x++
	addi	$t1, $t1, 1	#i++
	j	fatH2
breakFH2:
	beq	$a1, 37, breakHG1
	addi	$a1, $a1, 9
	j	HGroup1
breakHG1:

	# prepare for loop
	addi 	$a0, $0, 51   	# a0 = X 
	addi 	$a1, $0, 28   	# a1 = Y
	li	$t1, 0		#$t1 = i = 0
	li	$t2, 10		#t2=key
fatH3:
	beq	$t1, $t2, BreakFH3
	jal	drawPixel
	addi	$a0, $a0, 1	#x++
	addi	$t1, $t1, 1	#i++
	j	fatH3
BreakFH3:
	# prepare for loop
	addi 	$a0, $0, 6   	# a0 = X 
	addi 	$a1, $0, 28   	# a1 = Y
	li	$t1, 0		#$t1 = i = 0
	li	$t2, 24		#t2=key
fatV1:
	beq	$t1, $t2, BreakFV1
	jal	drawPixel
	addi	$a1, $a1, 1	#y++
	addi	$t1, $t1, 1	#i++
	j	fatV1
BreakFV1:
	# prepare for loop
	addi 	$a0, $0, 24   	# a0 = X 
	addi 	$a1, $0, 28   	# a1 = Y
	li	$t1, 0		#$t1 = i = 0
	li	$t2, 24		#t2=key
fatV2:
	beq	$t1, $t2, BreakFV2
	jal	drawPixel
	addi	$a1, $a1, 1	#y++
	addi	$t1, $t1, 1	#i++
	j	fatV2
BreakFV2:
	# prepare for loop
	addi 	$a0, $0, 47   	# a0 = X 
	addi 	$a1, $0, 28   	# a1 = Y
	li	$t1, 0		#$t1 = i = 0
	li	$t2, 24		#t2=key
fatV3:
	beq	$t1, $t2, BreakFV3
	jal	drawPixel
	addi	$a1, $a1, 1	#y++
	addi	$t1, $t1, 1	#i++
	j	fatV3
BreakFV3:
	# prepare for loop
	addi 	$a0, $0, 56   	# a0 = X 
	addi 	$a1, $0, 28   	# a1 = Y
	li	$t1, 0		#$t1 = i = 0
	li	$t2, 24		#t2=key
fatV4:
	beq	$t1, $t2, BreakFV4
	jal	drawPixel
	addi	$a1, $a1, 1	#y++
	addi	$t1, $t1, 1	#i++
	j	fatV4
BreakFV4:
	#title screen finished. Return
returnTitle:
	add	$ra, $0, $t7
	jr	$ra
####################################################
#draws the title of the game: Get Fat
#t7 = temp storage for old return address
#a2 = color of pixel, a0=x a1=y
#t1, t2 = control temps
paintGameOver:
	add	$t7, $0, $ra		#save $ra
	
	# set up starting position of blob
	addi 	$a0, $0, 12   	# a0 = X 
	addi 	$a1, $0, 12   	# a1 = Y
	addi 	$a2, $0, RED  	# a2 = red (ox00RRGGBB) - color
	
	#DRAW GAME
	#DRAW G
	# prepare for loop
	li	$t1, 0		#$t1 = i = 0
	li	$t2, 6		#t2=key
G1:	
	beq	$t1, $t2, BreakG1
	jal	drawPixel
	addi	$a0, $a0, 1	#X++
	addi	$t1, $t1, 1	#i++
	j	G1
BreakG1:
	# prepare for loop
	addi 	$a0, $0, 12   	# a0 = X 
	addi 	$a1, $0, 19   	# a1 = Y
	li	$t1, 0		#$t1 = i = 0
	li	$t2, 6		#t2=key
G2:	
	beq	$t1, $t2, BreakG2
	jal	drawPixel
	addi	$a0, $a0, 1	#X++
	addi	$t1, $t1, 1	#i++
	j	G2
BreakG2:
	# prepare for loop
	addi 	$a0, $0, 12   	# a0 = X 
	addi 	$a1, $0, 12   	# a1 = Y
	li	$t1, 0		#$t1 = i = 0
	li	$t2, 8		#t2=key
G3:	
	beq	$t1, $t2, BreakG3
	jal	drawPixel
	addi	$a1, $a1, 1	#Y++
	addi	$t1, $t1, 1	#i++
	j	G3
BreakG3:
	addi 	$a0, $0, 15   	# a0 = X 
	addi 	$a1, $0, 17   	# a1 = Y
	jal	drawPixel
	addi	$a0, $a0, 1
	jal	drawPixel
	addi	$a0, $a0, 1
	jal	drawPixel
	addi	$a1, $a1, 1
	jal	drawPixel
	
	#DRAW A
	addi 	$a0, $0, 21   	# a0 = X 
AVert:
	# prepare for loop
	addi 	$a1, $0, 12   	# a1 = Y
	li	$t1, 0		#$t1 = i = 0
	li	$t2, 8		#t2=key
A1:	
	beq	$t1, $t2, BreakA1
	jal	drawPixel
	addi	$a1, $a1, 1	#y++
	addi	$t1, $t1, 1	#i++
	j	A1
BreakA1:
	beq	$a0, 25, breakAVert
	addi	$a0, $a0, 4
	j	AVert
breakAVert:	

	addi 	$a1, $0, 12   	# a1 = Y
AHorz:
	# prepare for loop
	addi 	$a0, $0, 22   	# a0 = X 
	li	$t1, 0		#$t1 = i = 0
	li	$t2, 3		#t2=key
A2:	
	beq	$t1, $t2, BreakA2
	jal	drawPixel
	addi	$a0, $a0, 1	#x++
	addi	$t1, $t1, 1	#i++
	j	A2
BreakA2:
	beq	$a1, 15, breakAHorz
	addi	$a1, $a1, 3
	j	AHorz
breakAHorz:	

	#DRAW M
	addi 	$a0, $0, 28   	# a0 = X 
MVert:
	# prepare for loop
	addi 	$a1, $0, 12   	# a1 = Y
	li	$t1, 0		#$t1 = i = 0
	li	$t2, 8		#t2=key
M1:	
	beq	$t1, $t2, BreakM1
	jal	drawPixel
	addi	$a1, $a1, 1	#y++
	addi	$t1, $t1, 1	#i++
	j	M1
BreakM1:
	beq	$a0, 32, breakMVert
	addi	$a0, $a0, 2
	j	MVert
breakMVert:	
	addi	$a0, $0, 29 	#X
	addi	$a1, $0, 12	#Y
	jal 	drawPixel
	addi	$a0, $0, 31 	#X
	jal 	drawPixel
	
	#DRAW E
	# prepare for loop
	addi 	$a0, $0, 35   	# a0 = X 
	addi 	$a1, $0, 12   	# a1 = Y
	li	$t1, 0		#$t1 = i = 0
	li	$t2, 8		#t2=key
E1:	
	beq	$t1, $t2, BreakE1
	jal	drawPixel
	addi	$a1, $a1, 1	#Y++
	addi	$t1, $t1, 1	#i++
	j	E1
BreakE1:	
	#prepare for loop
	addi	$a1, $a1, -1
	li	$t1, 0		#$t1 = i = 0
	li	$t2, 4		#t2=key
E2:
	beq	$t1, $t2, BreakE2
	jal	drawPixel
	addi	$a0, $a0, 1	#x++
	addi	$t1, $t1, 1	#i++
	j	E2
BreakE2:	
	#prepare for loop
	addi	$a1, $a1, -4
	addi	$a0, $a0, -1
	li	$t1, 0		#$t1 = i = 0
	li	$t2, 4		#t2=key
E3:
	beq	$t1, $t2, BreakE3
	jal	drawPixel
	addi	$a0, $a0, -1	#x++
	addi	$t1, $t1, 1	#i++
	j	E3
BreakE3:
	#prepare for loop
	addi	$a1, $a1, -3
	addi	$a0, $a0, 1
	li	$t1, 0		#$t1 = i = 0
	li	$t2, 4		#t2=key
E4:
	beq	$t1, $t2, BreakE4
	jal	drawPixel
	addi	$a0, $a0, 1	#x++
	addi	$t1, $t1, 1	#i++
	j	E4
BreakE4:
	#DRAW OVER
	#DRAW O
	# prepare for loop
	addi 	$a0, $0, 12   	# a0 = X 
OVert:
	# prepare for loop
	addi 	$a1, $0, 24   	# a1 = Y
	li	$t1, 0		#$t1 = i = 0
	li	$t2, 7		#t2=key
O1:	
	beq	$t1, $t2, BreakO1
	jal	drawPixel
	addi	$a1, $a1, 1	#y++
	addi	$t1, $t1, 1	#i++
	j	O1
BreakO1:
	beq	$a0, 37, breakOVert
	addi	$a0, $a0, 25
	j	OVert
breakOVert:	

	addi 	$a1, $0, 24   	# a1 = Y
OHorz:
	# prepare for loop
	addi 	$a0, $0, 12   	# a0 = X 
	li	$t1, 0		#$t1 = i = 0
	li	$t2, 26		#t2=key
O2:	
	beq	$t1, $t2, BreakO2
	jal	drawPixel
	addi	$a0, $a0, 1	#x++
	addi	$t1, $t1, 1	#i++
	j	O2
BreakO2:
	beq	$a1, 30, breakOHorz
	addi	$a1, $a1, 6
	j	OHorz
breakOHorz:	

	#DRAW V
	# prepare for loop
	addi 	$a0, $0, 39   	# a0 = X 
VVert:
	# prepare for loop
	addi 	$a1, $0, 24   	# a1 = Y
	li	$t1, 0		#$t1 = i = 0
	li	$t2, 5		#t2=key
V1:	
	beq	$t1, $t2, BreakLetterV1
	jal	drawPixel
	addi	$a1, $a1, 1	#y++
	addi	$t1, $t1, 1	#i++
	j	V1
BreakLetterV1:
	beq	$a0, 43, breakVVert
	addi	$a0, $a0, 4
	j	VVert
breakVVert:		
	addi	$a0, $0, 40	#x
	addi	$a1, $0, 29	#y
	jal	drawPixel
	addi	$a0, $a0, 2	#x
	jal	drawPixel
	addi	$a0, $a0, -1	#x
	addi	$a1, $a1, 1	#y
	jal	drawPixel
	
	#DRAW E
	# prepare for loop
	addi 	$a0, $0, 45   	# a0 = X 
	addi 	$a1, $0, 24   	# a1 = Y
	li	$t1, 0		#$t1 = i = 0
	li	$t2, 7		#t2=key
Etwo1:	
	beq	$t1, $t2, Break2ndE1
	jal	drawPixel
	addi	$a1, $a1, 1	#Y++
	addi	$t1, $t1, 1	#i++
	j	Etwo1
Break2ndE1:	
	addi 	$a1, $0, 24   	# a1 = Y
ETwoVert:
	# prepare for loop
	addi 	$a0, $0, 45   	# a0 = X 
	li	$t1, 0		#$t1 = i = 0
	li	$t2, 5		#t2=key
Etwo2:	
	beq	$t1, $t2, bkEtwo2
	jal	drawPixel
	addi	$a0, $a0, 1	#y++
	addi	$t1, $t1, 1	#i++
	j	Etwo2
bkEtwo2:
	beq	$a1, 30, breakETwoVert
	addi	$a1, $a1, 3
	j	ETwoVert
breakETwoVert:	

	#DRAW R
	# prepare for loop
	addi	$a0, $0, 52	#x
	addi	$a1, $0, 24	#y
	li	$t1, 0		#$t1 = i = 0
	li	$t2, 4		#t2=key
R1:	
	beq	$t1, $t2, BreakR1
	jal	drawPixel
	addi	$a0, $a0, 1	#X++
	addi	$t1, $t1, 1	#i++
	j	R1
BreakR1:
	# prepare for loop
	addi	$a0, $0, 52	#x
	addi	$a1, $0, 27	#y
	li	$t1, 0		#$t1 = i = 0
	li	$t2, 4		#t2=key
R2:	
	beq	$t1, $t2, BreakR2
	jal	drawPixel
	addi	$a0, $a0, 1	#X++
	addi	$t1, $t1, 1	#i++
	j	R2
BreakR2:
	# prepare for loop
	addi	$a0, $0, 52	#x
	addi	$a1, $0, 24	#y
	li	$t1, 0		#$t1 = i = 0
	li	$t2, 7		#t2=key
R3:	
	beq	$t1, $t2, BreakR3
	jal	drawPixel
	addi	$a1, $a1, 1	#y++
	addi	$t1, $t1, 1	#i++
	j	R3
BreakR3:
	# prepare for loop
	addi	$a0, $0, 55	#x
	addi	$a1, $0, 24	#y
	li	$t1, 0		#$t1 = i = 0
	li	$t2, 4		#t2=key
R4:	
	beq	$t1, $t2, BreakR4
	jal	drawPixel
	addi	$a1, $a1, 1	#y++
	addi	$t1, $t1, 1	#i++
	j	R4
BreakR4:
	addi	$a0, $a0, -1
	jal	drawPixel
	addi	$a1, $a1, 1
	jal	drawPixel
	addi	$a0, $a0, 1
	addi	$a1, $a1, 1
	jal	drawPixel
	
	#DRAW SAD FACE
	# prepare for loop
	addi	$a0, $0, 19	#x
	addi	$a1, $0, 37	#y
	li	$t1, 0		#$t1 = i = 0
	li	$t2, 8		#t2=key
Sad1:	
	beq	$t1, $t2, BreakSad1
	jal	drawPixel
	addi	$a1, $a1, 1	#y++
	addi	$t1, $t1, 1	#i++
	j	Sad1
BreakSad1:
	# prepare for loop
	addi	$a0, $0, 26	#x
	addi	$a1, $0, 37	#y
	li	$t1, 0		#$t1 = i = 0
	li	$t2, 8		#t2=key
Sad2:	
	beq	$t1, $t2, BreakSad2
	jal	drawPixel
	addi	$a1, $a1, 1	#y++
	addi	$t1, $t1, 1	#i++
	j	Sad2
BreakSad2:
	# prepare for loop
	addi	$a0, $0, 17	#x
	addi	$a1, $0, 48	#y
	li	$t1, 0		#$t1 = i = 0
	li	$t2, 8		#t2=key
Sad3:	
	beq	$t1, $t2, BreakSad3
	jal	drawPixel
	addi	$a1, $a1, 1	#y++
	addi	$t1, $t1, 1	#i++
	j	Sad3
BreakSad3:
	# prepare for loop
	addi	$a0, $0, 28	#x
	addi	$a1, $0, 48	#y
	li	$t1, 0		#$t1 = i = 0
	li	$t2, 8		#t2=key
Sad4:	
	beq	$t1, $t2, BreakSad4
	jal	drawPixel
	addi	$a1, $a1, 1	#y++
	addi	$t1, $t1, 1	#i++
	j	Sad4
BreakSad4:
	# prepare for loop
	addi	$a0, $0, 18	#x
	addi	$a1, $0, 48	#y
	li	$t1, 0		#$t1 = i = 0
	li	$t2, 10		#t2=key
Sad5:	
	beq	$t1, $t2, BreakSad5
	jal	drawPixel
	addi	$a0, $a0, 1	#x++
	addi	$t1, $t1, 1	#i++
	j	Sad5
BreakSad5:
	#add tear
	addi	$a0, $0, 27
	addi	$a1, $0, 45
	addi	$a2, $0, BLUE
	jal	drawPixel
	addi	$a1, $a1, 1
	jal	drawPixel
	
	#game over screen finished. Return
returnGameOver:
	add	$ra, $0, $t7
	jr	$ra