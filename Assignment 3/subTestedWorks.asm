# Nicholas BELEV  261076111

.data
bitmapDisplay: .space 0x80000 # enough memory for a 512x256 bitmap display
resolution: .word  512 256    # width and height of the bitmap display

windowlrbt: 
.float -2.5 2.5 -1.25 1.25                    # good window for viewing Julia sets
#.float -3 2 -1.25 1.25                      # good window for viewing full Mandelbrot set
#.float -0.807298 -0.799298 -0.179996 -0.175996         # double spiral
#.float -1.019741354 -1.013877846  -0.325120847 -0.322189093   # baby Mandelbrot
 
bound: .float 100    # bound for testing for unbounded growth during iteration
maxIter: .word 128   # maximum iteration count to be used by drawJulia and drawMandelbrot
scale: .word 16      # scale parameter used by computeColour

# Julia constants for testing, or likewise for more examples see
# https://en.wikipedia.org/wiki/Julia_set#Quadratic_polynomials  
JuliaC0:  .float 0    0    # should give you a circle, a good test, though boring!
JuliaC1:  .float 0.25 0.5 
JuliaC2:  .float 0    0.7 
JuliaC3:  .float 0    0.8 

# a demo starting point for iteration tests
z0: .float  0 0

# TODO: define various constants you need in your .data segment here

# String constants
plus:      .asciiz " + "
i_char:    .asciiz " i"
new_line:  .asciiz "\n"
equal: .asciiz " = "
x:  .asciiz "x"
y:  .asciiz "y"

# Float Constants
ayy: .float 0.25
bee: .float 0.5
x0: .float 1.0
y0: .float 0.0

########################################################################################
.text

	# TODO: Write your function testing code here
	
	# Test drawJulia and drawMandelbrot
	la $t4, JuliaC0
	lwc1 $f12, 0($t4)
	lwc1 $f13, 4($t4)
	jal drawJulia
		
	# Test pixel2ComplexInWindow
	#li $a0, 512
	#li $a1, 256
	#jal pixel2ComplexInWindow

	# Test iterateVerbose
	#li $a0, 10
	#lwc1 $f12, ayy
	#lwc1 $f13, bee
	#lwc1 $f14, x0
	#lwc1 $f15, y0
        #jal iterateVerbose
    
	# Test multComplex
	#la $t0, JuliaC1
        #lwc1 $f12, 0($t0)
        #lwc1 $f13, 4($t0)
        #lwc1 $f14, 0($t0)
        #lwc1 $f15, 4($t0)
        #jal multComplex
        
        #  print multCplx with new values
        #mov.s $f12, $f0
        #mov.s $f13, $f1
    	#jal printComplex            
    	    	
    	# Test print new ln
    	#jal printNewLine            
    
    	li $v0, 10                  # Exit
    	syscall
    
# TODO: Write your functions to implement various assignment objectives here


    printComplex:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
        
        li $v0, 2          # set syscall flt print
        mov.s $f12, $f12   # move float in $f12 to $f12 for consistency sake
        syscall            # print f12
        
        la $a0, plus      # Load space into $a0 for printing
        li $v0, 4         # Set syscall number for printing string to 4
        syscall           # Prnt delimiter
        
        li $v0, 2           # Syscall print float
        mov.s $f12, $f13    # $f13 to $f12 cuz syscall only prints f12
        syscall             # print f13
        
        la $a0, i_char     # Load "i" into $a0 for printing
        li $v0, 4          # Set syscall number for printing string to 4
        syscall            # Print "i"
        
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra             
    
    
    printNewLine:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
        
        la $a0, new_line   
        li $v0, 4          
        syscall            
        
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra     
        
        
    multComplex:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    	mul.s $f16, $f12, $f14  # ac
    	mul.s $f18, $f13, $f15  # bd
    
    	mul.s $f12, $f12, $f15  # ad
    	mul.s $f14, $f13, $f14  # bc
    
    	sub.s $f0, $f16, $f18   # ac - bd
    	add.s $f1, $f12, $f14   # ad + bc
    	
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra               # head out
    
    		
    iterateVerbose:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    	
    	addi $sp, $sp, -4
        sw $s0, 0($sp) ##restore after
    	move $s0, $a0    # n constant max s0
    	
    	addi $sp, $sp, -4
        sw $s1, 0($sp) ##restore after
        li $s1, 0      # incrementer s1
    	
    	addi $sp, $sp, -4
        swc1 $f20, 0($sp) ##restore after
    	mov.s $f20, $f12 # save a to f20 constant
    	
    	addi $sp, $sp, -4
        swc1 $f21, 0($sp) ##restore after
    	mov.s $f21, $f13  # save b to f21 constant
    	
    	addi $sp, $sp, -4
        swc1 $f22, 0($sp) ##restore after
        mov.s $f22, $f14 # x var
        
        addi $sp, $sp, -4
        swc1 $f23, 0($sp) ##restore after
        mov.s $f23, $f15 # y var
    	
    	la $t7, bound
    	addi $sp, $sp, -4
        swc1 $f24, 0($sp) ##restore after
    	lwc1 $f24, 0($t7)    # bound const
    	
    	ivLoop:
    	    bge $s1, $s0, ivDone # allow a maximum of n iterations, then branch
    	    
    	    mul.s $f6, $f22, $f22
    	    mul.s $f7, $f23, $f23
    	    add.s $f8, $f6, $f7 #calculate squared magnitude
    	    
    	    c.lt.s $f24, $f8 # bound < x^2 + y^2
    	    bc1t ivDone # branch to end of loop
    	    
    	    la $a0, x
    	    li $v0, 4
    	    syscall
    	    la $a0, ($s1)
    	    li $v0, 1
    	    syscall
    	    la $a0, plus
    	    li $v0, 4
    	    syscall
    	    la $a0, y
    	    li $v0, 4
    	    syscall
    	    la $a0, ($s1)
    	    li $v0, 1
    	    syscall
    	    la $a0, i_char
    	    li $v0, 4
    	    syscall
    	    la $a0, equal
    	    li $v0, 4
    	    syscall
    	    
    	    addi $s1, $s1, 1 # increment counter
    	    
    	    mov.s $f12, $f22 # get x ready for printing
    	    mov.s $f13, $f23 # get y ready for printing
    	    
    	    jal printComplex
    	    jal printNewLine
    	    
    	    mov.s $f12, $f22
    	    mov.s $f13, $f23
    	    mov.s $f14, $f22
    	    mov.s $f15, $f23
    	    
    	    addi $sp, $sp, -4
            sw $ra, 0($sp)
    	    jal multComplex # square the complex numba
            lw $ra, 0($sp)
            addi $sp, $sp, 4
            
            add.s $f22, $f0, $f20 # f22 = new x + a
            add.s $f23, $f1, $f21 # f22 = new y + b
    	    
    	j ivLoop
    	    
    ivDone:
    	subi $s1, $s1, 1
    	move $a0, $s1 # get increment reached value ready and printed
    	li $v0, 1 
    	syscall # print iteration count
    	move $v0, $s1 # set v0 to be correct return value
    	   
        lwc1 $f24, 0($sp)
        addi $sp, $sp, 4
    	   
    	lwc1 $f23, 0($sp)
        addi $sp, $sp, 4
           
        lwc1 $f22, 0($sp)
        addi $sp, $sp, 4
           
        lwc1 $f21, 0($sp)
        addi $sp, $sp, 4
           
        lwc1 $f20, 0($sp)
        addi $sp, $sp, 4
           
        lw $s1, 0($sp)
        addi $sp, $sp, 4
           
        lw $s0, 0($sp)
        addi $sp, $sp, 4
    	   
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra               # head out
    	
 
    iterate:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    	
    	addi $sp, $sp, -4
        sw $s0, 0($sp) ##restore after
    	move $s0, $a0    # n constant max s0
    	
    	addi $sp, $sp, -4
        sw $s1, 0($sp) ##restore after
        li $s1, 0      # incrementer s1
    	
    	addi $sp, $sp, -4
        swc1 $f20, 0($sp) ##restore after
    	mov.s $f20, $f12 # save a to f20 constant
    	
    	addi $sp, $sp, -4
        swc1 $f21, 0($sp) ##restore after
    	mov.s $f21, $f13  # save b to f21 constant
    	
    	addi $sp, $sp, -4
        swc1 $f22, 0($sp) ##restore after
        mov.s $f22, $f14 # x var
        
        addi $sp, $sp, -4
        swc1 $f23, 0($sp) ##restore after
        mov.s $f23, $f15 # y var
    	
    	la $t7, bound
    	addi $sp, $sp, -4
        swc1 $f24, 0($sp) ##restore after
    	lwc1 $f24, 0($t7)    # bound const
    	
    	iLoop2:
    	    bge $s1, $s0, iDone2 # allow a maximum of n iterations, then branch
    	    
    	    mul.s $f6, $f22, $f22
    	    mul.s $f7, $f23, $f23
    	    add.s $f8, $f6, $f7 #calculate squared magnitude
    	    
    	    c.lt.s $f24, $f8 # bound < x^2 + y^2
    	    bc1t iDone2 # branch to end of loop
    	    
    	    addi $s1, $s1, 1 # increment counter
    	    
    	    mov.s $f12, $f22 # get x ready for printing
    	    mov.s $f13, $f23 # get y ready for printing
    	    
    	    mov.s $f12, $f22
    	    mov.s $f13, $f23
    	    mov.s $f14, $f22
    	    mov.s $f15, $f23
    	    
    	    addi $sp, $sp, -4
            sw $ra, 0($sp)
    	    jal multComplex # square the complex numba
            lw $ra, 0($sp)
            addi $sp, $sp, 4
            
            add.s $f22, $f0, $f20 # f22 = new x + a
            add.s $f23, $f1, $f21 # f22 = new y + b
    	    
    	j iLoop2
    	    
    iDone2:
    	subi $s1, $s1, 1
    	move $v0, $s1 # set v0 to be correct return value
    	   
        lwc1 $f24, 0($sp)
        addi $sp, $sp, 4
    	   
        lwc1 $f23, 0($sp)
        addi $sp, $sp, 4
           
        lwc1 $f22, 0($sp)
        addi $sp, $sp, 4
           
        lwc1 $f21, 0($sp)
        addi $sp, $sp, 4
           
        lwc1 $f20, 0($sp)
        addi $sp, $sp, 4
           
        lw $s1, 0($sp)
        addi $sp, $sp, 4
           
        lw $s0, 0($sp)
        addi $sp, $sp, 4
    	   
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra               # head out   	     
    	
    	
    pixel2ComplexInWindow:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
        
        addi $sp, $sp, -4
        swc1 $f20, 0($sp)
        move $t7, $a0 
        mtc1 $t7, $f20
        cvt.s.w $f20, $f20 # get col as flt
        
        addi $sp, $sp, -4
        swc1 $f21, 0($sp)
        move $t7, $a1
        mtc1 $t7, $f21
        cvt.s.w $f21, $f21 # get row as flt
        
        la $t7, resolution
        lw $t6, 0($t7)
        lw $t5, 4($t7)
        
        addi $sp, $sp, -4
        swc1 $f22, 0($sp)
        mtc1 $t6, $f22
        cvt.s.w $f22, $f22 # get width as float
        
        addi $sp, $sp, -4
        swc1 $f23, 0($sp)
        mtc1 $t5, $f23
        cvt.s.w $f23, $f23 # get height as float
        
        la $t7, windowlrbt
        
        addi $sp, $sp, -4
        swc1 $f24, 0($sp)
        lwc1 $f24, 0($t7) # get left
        
        addi $sp, $sp, -4
        swc1 $f25, 0($sp)
        lwc1 $f25, 4($t7) # get right
        
        addi $sp, $sp, -4
        swc1 $f26, 0($sp)
        lwc1 $f26, 8($t7) # get bottom
        
        addi $sp, $sp, -4
        swc1 $f27, 0($sp)
        lwc1 $f27, 12($t7) # get top
        
        sub.s $f4, $f25, $f24 # r - l
        mul.s $f4, $f4, $f20 # col(r - l)
        div.s $f4, $f4, $f22 # col/w * (r - l)
        add.s $f4, $f4, $f24 # (col/w)*(r - l) + l
        mov.s $f0, $f4 # return value for x
        
        sub.s $f5, $f27, $f26 # t - b
        mul.s $f5, $f5, $f21 # row(t - b)
        div.s $f5, $f5, $f23 # row/h * (t - b)
        add.s $f5, $f5, $f26 # (row/h)*(t - b) + b
        mov.s $f1, $f5 # return value for y
        
        lwc1 $f27, 0($sp)
        addi $sp, $sp, 4
        
        lwc1 $f26, 0($sp)
        addi $sp, $sp, 4
        
        lwc1 $f25, 0($sp)
        addi $sp, $sp, 4
        
        lwc1 $f24, 0($sp)
        addi $sp, $sp, 4
        
        lwc1 $f23, 0($sp)
        addi $sp, $sp, 4
        
        lwc1 $f22, 0($sp)
        addi $sp, $sp, 4
        
        lwc1 $f21, 0($sp)
        addi $sp, $sp, 4
        
        lwc1 $f20, 0($sp)
        addi $sp, $sp, 4
        
        # Testing script
        #mov.s $f12, $f0
        #mov.s $f13, $f1
        #jal printComplex
        #jal printNewLine
        
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra
    
    
    drawJulia:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
        addi $sp, $sp, -4
        swc1 $f20, 0($sp) ##restore after
    	mov.s $f20, $f12 # save a to f20
    	
    	addi $sp, $sp, -4
        swc1 $f21, 0($sp) ##restore after
    	mov.s $f21, $f13 # save b to f21
    	
    	la $t7, bitmapDisplay
    	addi $sp, $sp, -4
        sw $s0, 0($sp) ##restore after
    	move $s0, $t7 # save bitmap display start address
    	
    	la $t7, resolution
    	
    	addi $sp, $sp, -4
        sw $s1, 0($sp) ##restore after
    	lw $s1, 0($t7) # save max width
    	
    	addi $sp, $sp, -4
        sw $s2, 0($sp) ##restore after
    	lw $s2, 4($t7) # save max height
    	
    	addi $sp, $sp, -4
        sw $s3, 0($sp) ##restore after
    	li $s3, 0 # x coord counter ie col
    	
    	addi $sp, $sp, -4
        sw $s4, 0($sp) ##restore after
    	li $s4, 0 # y coord counter ie row
    	
    	la $t7, maxIter
    	addi $sp, $sp, -4
        sw $s5, 0($sp) ##restore after
    	lw $s5, 0($t7) # maxIterConstant
    	
    	juliaLoop:
    	    bge $s4, $s2, juliaDone # when height reaches 256, we're done cuz we go 0 to 255
    	    
    	    # do Julia operations to current (col, row)
    	    move $a0, $s3 # col
    	    move $a1, $s4 # row
    	    jal pixel2ComplexInWindow # gives us f0 as x0 and f1 as y0 i start point
    	    move $a0, $s5 # load n
    	    mov.s $f12, $f20 # get a
    	    mov.s $f13, $f21 # get b
    	    mov.s $f14, $f0 # load x0
    	    mov.s $f15, $f1 # load y0
    	    jal iterate # returns iter count in v0
    	    #######
    	    subi $t7, $s5, 1
    	    bge $v0, $t7, maxReached # only gonna execute 505-509 if $v0 < $s5 ie bound not reached
    	        move $a0, $v0 # set argument
    	        jal computeColour # returns ARGB in $v0
    	        sw $v0, 0($s0)
    	        j skipMaxReached
    	    
    	    maxReached: # if v0 >= s5 bound was reached, so it's in Julia set so color black
    	        li $t6, 0
    	        sw $t6, 0($s0)
    	    
    	    skipMaxReached: # does nothing
    	    
    	    addi $s0, $s0, 4 # increment pixel address after we're done working with previous one
    	    
    	    addi $t7, $s1, -1 # decrement width for comparison
    	    blt $s3, $t7, noNewRow # if we're not done w last x coord in the row, dont reset x coord to 0 nor increment y
    	        li $s3, 0 # reset x coord or col
    	        addi $s4, $s4, 1 # increment y coord or row
    	    j skipNoNewRow
    	    
    	    noNewRow:
    	      addi $s3, $s3, 1 # increment x coord by 1 until it gets to 511
    	    
    	    skipNoNewRow: # does nothing
    	    
    	j juliaLoop    
    	
    juliaDone:
        lw $s5, 0($sp)
        addi $sp, $sp, 4
    
    	lw $s4, 0($sp)
        addi $sp, $sp, 4
    	
    	lw $s3, 0($sp)
        addi $sp, $sp, 4
    	
    	lw $s2, 0($sp)
        addi $sp, $sp, 4
    	
    	lw $s1, 0($sp)
        addi $sp, $sp, 4
    	
    	lw $s0, 0($sp)
        addi $sp, $sp, 4
    	
    	lwc1 $f21, 0($sp)
        addi $sp, $sp, 4
    	
    	lwc1 $f20, 0($sp)
        addi $sp, $sp, 4
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra # done popping stack


    drawMandelbrot:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
        addi $sp, $sp, -4
        swc1 $f20, 0($sp) ##restore after
        li $t7, 0
        mtc1 $t7, $f20
        cvt.s.w $f20, $f20 # x0 = 0
    	
    	addi $sp, $sp, -4
        swc1 $f21, 0($sp) ##restore after
    	li $t7, 0
        mtc1 $t7, $f21
        cvt.s.w $f21, $f21 # y0 = 0
    	
    	la $t7, bitmapDisplay
    	addi $sp, $sp, -4
        sw $s0, 0($sp) ##restore after
    	move $s0, $t7 # save bitmap display start address
    	
    	la $t7, resolution
    	
    	addi $sp, $sp, -4
        sw $s1, 0($sp) ##restore after
    	lw $s1, 0($t7) # save max width
    	
    	addi $sp, $sp, -4
        sw $s2, 0($sp) ##restore after
    	lw $s2, 4($t7) # save max height
    	
    	addi $sp, $sp, -4
        sw $s3, 0($sp) ##restore after
    	li $s3, 0 # x coord counter ie col
    	
    	addi $sp, $sp, -4
        sw $s4, 0($sp) ##restore after
    	li $s4, 0 # y coord counter ie row
    	
    	la $t7, maxIter
    	addi $sp, $sp, -4
        sw $s5, 0($sp) ##restore after
    	lw $s5, 0($t7) # maxIterConstant
    	
    	mandeLoop:
    	    bge $s4, $s2, mandeDone # when height reaches 256, we're done cuz we go 0 to 255
    	    
    	    # do Julia operations to current (col, row)
    	    move $a0, $s3 # col
    	    move $a1, $s4 # row
    	    jal pixel2ComplexInWindow # gives us f0 as a and f1 as b
    	    move $a0, $s5 # load n
    	    mov.s $f12, $f0 # get a
    	    mov.s $f13, $f1 # get b
    	    mov.s $f14, $f20 # load x our real
    	    mov.s $f15, $f21 # load y our imaginary
    	    jal iterate # returns iter count in v0
    	    #######
    	    subi $t7, $s5, 1
    	    bge $v0, $t7, max2Reached # only gonna execute 505-509 if $v0 < $s5 ie bound not reached
    	        move $a0, $v0 # set argument
    	        jal computeColour # returns ARGB in $v0
    	        sw $v0, 0($s0)
    	        j skipMax2Reached
    	    
    	    max2Reached: # if v0 >= s5 bound was reached, so it's in Julia set so color black
    	        li $t6, 0
    	        sw $t6, 0($s0)
    	    
    	    skipMax2Reached: # does nothing
    	    
    	    addi $s0, $s0, 4 # increment pixel address after we're done working with previous one
    	    
    	    addi $t7, $s1, -1 # decrement width for comparison
    	    blt $s3, $t7, no2NewRow # if we're not done w last x coord in the row, dont reset x coord to 0 nor increment y
    	        li $s3, 0 # reset x coord or col
    	        addi $s4, $s4, 1 # increment y coord or row
    	    j skipNo2NewRow
    	    
    	    no2NewRow:
    	      addi $s3, $s3, 1 # increment x coord by 1 until it gets to 511
    	    
    	    skipNo2NewRow: # does nothing
    	    
    	j mandeLoop    
    	
    mandeDone:
        lw $s5, 0($sp)
        addi $sp, $sp, 4
    
    	lw $s4, 0($sp)
        addi $sp, $sp, 4
    	
    	lw $s3, 0($sp)
        addi $sp, $sp, 4
    	
    	lw $s2, 0($sp)
        addi $sp, $sp, 4
    	
    	lw $s1, 0($sp)
        addi $sp, $sp, 4
    	
    	lw $s0, 0($sp)
        addi $sp, $sp, 4
    	
    	lwc1 $f21, 0($sp)
        addi $sp, $sp, 4
    	
    	lwc1 $f20, 0($sp)
        addi $sp, $sp, 4
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra # done popping stack
    
########################################################################################
# Computes a colour corresponding to a given iteration count in $a0
# The colours cycle smoothly through green blue and red, with a speed adjustable 
# by a scale parameter defined in the static .data segment
computeColour:
	la $t0 scale
	lw $t0 ($t0)
	mult $a0 $t0
	mflo $a0
ccLoop:
	slti $t0 $a0 256
	beq $t0 $0 ccSkip1
	li $t1 255
	sub $t1 $t1 $a0
	sll $t1 $t1 8
	add $v0 $t1 $a0
	jr $ra
ccSkip1:
  	slti $t0 $a0 512
	beq $t0 $0 ccSkip2
	addi $v0 $a0 -256
	li $t1 255
	sub $t1 $t1 $v0
	sll $v0 $v0 16
	or $v0 $v0 $t1
	jr $ra
ccSkip2:
	slti $t0 $a0 768
	beq $t0 $0 ccSkip3
	addi $v0 $a0 -512
	li $t1 255
	sub $t1 $t1 $v0
	sll $t1 $t1 16
	sll $v0 $v0 8
	or $v0 $v0 $t1
	jr $ra
ccSkip3:
 	addi $a0 $a0 -768
 	j ccLoop



