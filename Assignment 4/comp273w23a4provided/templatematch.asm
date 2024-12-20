# BELEV
# Nicholas
# 261076111

# 1. Do the base addresses of image and error buffers fall into the same block of the direct mapped cache?
#     Yes, static data (ie. that we use first for the image buffer and then for the error buffer, shown on the
# bitmap display) starts at the address 0x10010000.  Then we get the first 128 (complete) rows of the bitmap
# from the image buffer (512 x 128 pixels x 4 bytes per pixel = 0x40000).  Following this, the next 128 rows 
# come from error buffer, and have the same dimensions and amount of data (0x40000).  Regardless, accounting
# for the image buffer data which comes first, this will span from 0x10010000 to the address before 0x10050000
# Hence, image buffer starts at 0x10010000, and error buffer starts at 0x10050000, which are both divisible by 8
# (ie. the total number of blocks in the direct mapped cache), so both base addresses will fall into the same 
# block of a direct mapped cache.

# 2. For the templateMatchFast and a direct mapped cache, does it matter if the template buffer base address
# falls into the same block as the image or error buffer base address?
#     It does not matter (not significantly anyways):
#     Empirically, upon testing different base address offsets for the template buffer, the number of cache
# misses is the same, hence, regardless of the block location or if the template buffer and image / error
# buffers are in the same block, there is no benefit or harm to the conflict misses that occur.
#     As for a more theoretical reasoning, this is because the first thing we do in templateMatchFast (in each 
# outer for loop) is load an entire row (both in image terms and in cache/block terms) from the template buffer
# and store their corresponding intensities into registers.  After that, the cache may or may not replace the
# template buffer block we loaded, but this only happens once for the entire outer for loop; so 8 times total
# which means a negligible amount of conflict misses can occur even if the template buffer base address maps
# to the same block as the image or error buffer, hence the impact doesn't matter.

.data
displayBuffer:  .space 0x40000 # space for 512x256 bitmap display // actually it's 512x128 worth of image 
errorBuffer:    .space 0x40000 # space to store match function    // and 512x128 worth of error
templateBuffer: .space 0x100   # space for 8x8 template
imageFileName:    .asciiz "pxlcon512x256cropgs.raw" 
templateFileName: .asciiz "template8x8gs.raw"
# struct bufferInfo { int *buffer, int width, int height, char* filename }
imageBufferInfo:    .word displayBuffer  512 128  imageFileName #change back to 128 from 16!!
errorBufferInfo:    .word errorBuffer    512 128  0     #change back to 128 from 16!!
templateBufferInfo: .word templateBuffer 8   8    templateFileName

.text
main:	la $a0, imageBufferInfo
	jal loadImage
	la $a0, templateBufferInfo
	jal loadImage
	la $a0, imageBufferInfo
	la $a1, templateBufferInfo
	la $a2, errorBufferInfo
	jal matchTemplate        # MATCHING DONE HERE
	la $a0, errorBufferInfo
	jal findBest
	la $a0, imageBufferInfo
	move $a1, $v0
	jal highlight
	la $a0, errorBufferInfo	
	jal processError
	li $v0, 10		# exit
	syscall
	

##########################################################
# matchTemplate( bufferInfo imageBufferInfo, bufferInfo templateBufferInfo, bufferInfo errorBufferInfo ) (a0, a1, a2)
# NOTE: struct bufferInfo { int *buffer, int width, int height, char* filename }
matchTemplate:	
	
	# TODO: write this function!
	addi $sp, $sp, -4
        sw $ra, 0($sp)
        
        addi $sp, $sp, -4
        sw $s0, 0($sp)
        li $s0, 0 # y variable
        
        addi $sp, $sp, -4
        sw $s1, 0($sp)
        li $s1, 0 # x variable
        
        addi $sp, $sp, -4
        sw $s2, 0($sp)
        li $s2, 0 # j variable
        
        addi $sp, $sp, -4
        sw $s3, 0($sp)
        li $s3, 0 # i variable
    
    L1:
    lw $t7, 8($a0)
    subi $t7, $t7, 8
    bgt $s0, $t7, endL1 #for ( int y = 0; y <= height - 8; y++ )
        
        L2:
        lw $t6, 4($a0)
        subi $t6, $t6, 8
        bgt $s1, $t6, endL2 #for ( int x = 0; x <= width - 8; x++ )
        
            SAD1:
            bge $s2, 8, endSAD1 #for ( int j = 0; j < 8; j++ )
        
                SAD2:
                bge $s3, 8, endSAD2 #for ( int i = 0; i < 8; i++ )
                	######################
                	#Get pixel I[x+i][y+j]
                	lw $t0, 0($a0) # get imageBufferInfo --> displayBuffer --> Start address
                	add $t1, $s1, $s3 # x+i
                	add $t2, $s0, $s2 # y+j
                	lw $t5, 4($a0) # get width
                	mult $t5, $t2
                	mflo $t5 # (width * row) row is y+j I'm guessing
                	add $t5, $t5, $t1 # ((width * row) + col), col is x+i
                	sll $t5, $t5, 2 # multiply by 4 faster
                	add $t0, $t0, $t5 # $t0 now has address of pixel I[x+i][y+j]
                	lbu $t5, 0($t0) # $t5 now has the intensity of the pixel stored at address $t0
                	######################
                
                	######################
                	#get pixel T[i][j]
                	lw $t0, 0($a1) # get templateBufferInfo --> templateBuffer --> Start address
                	lw $t4, 4($a1) # get width
                	mult $t4, $s2
                	mflo $t4 # (width * row)
                	add $t4, $t4, $s3 # ((width * row) + col), assuming col is i
                	sll $t4, $t4, 2 # multiply by 4 faster
                	add $t0, $t0, $t4 # $t0 now has address of pixel T[i][j]
                	lbu $t4, 0($t0) # $t4 now has the intensity of the pixel stored at address $t0
                	######################
                	
                	######################
                	#subtract I - T
                	sub $t1, $t5, $t4
                	#absolute value the result
                	abs $t1, $t1
                	######################
                
                	######################
                	#Get pixel SAD[x][y] address
                	lw $t0, 0($a2) # get errorBufferInfo --> errorBuffer --> Start address
                	lw $t4, 4($a2) # get width
                	mult $t4, $s0
                	mflo $t4 # (width * row)
                	add $t4, $t4, $s1 # ((width * row) + col), assuming col is x
                	sll $t4, $t4, 2 # multiply by 4 faster
                	add $t0, $t0, $t4 # $t0 now has address of pixel SAD[x][y]
                	
                	lw $t2, 0($t0) # $t2 now has the value of SAD inside $t0 pixel
                	add $t3, $t1, $t2 # append current iteration value of SAD function to value stored in [x][y] pixel
                	sw $t3, 0($t0) # store current SAD value to correct pixel
                	######################

                addi $s3, $s3, 1
                j SAD2
                endSAD2:
                #set i back to 0
                li $s3, 0
        
            addi $s2, $s2, 1
            j SAD1
            endSAD1:
            #set j back to 0
            li $s2, 0
 
        addi $s1, $s1, 1
        j L2
        endL2:
        #set x back to 0
        li $s1, 0
        
    addi $s0, $s0, 1
    j L1
    endL1:
        
        lw $s3, 0($sp)
        addi $sp, $sp, 4
        
        lw $s2, 0($sp)
        addi $sp, $sp, 4
        
        lw $s1, 0($sp)
        addi $sp, $sp, 4
        
        lw $s0, 0($sp)
        addi $sp, $sp, 4
        
        lw $ra, 0($sp)
        addi $sp, $sp, 4
	jr $ra	
	
##########################################################
# matchTemplateFast( bufferInfo imageBufferInfo, bufferInfo templateBufferInfo, bufferInfo errorBufferInfo )
# NOTE: struct bufferInfo { int *buffer, int width, int height, char* filename }
matchTemplateFast:	
	
	# TODO: write this function!
	addi $sp, $sp, -4
        sw $ra, 0($sp)
        
        addi $sp, $sp, -4
        sw $s0, 0($sp)
        li $s0, 0 # j variable
        
        addi $sp, $sp, -4
        sw $s1, 0($sp)
        li $s1, 0 # y variable
        
        addi $sp, $sp, -4
        sw $s2, 0($sp)
        li $s2, 0 # x variable
        
        addi $sp, $sp, -4
        sw $s3, 0($sp) # extra
        
        addi $sp, $sp, -4
        sw $s4, 0($sp) # extra
        
        addi $sp, $sp, -4
        sw $s5, 0($sp) # extra
        
        addi $sp, $sp, -4
        sw $s6, 0($sp) # extra
    
    
    FL1:
    bge $s0, 8, endFL1 #for ( int j = 0; j < 8; j++ )

        #get pixel intensity of T[0][j]: j is rows!!!
        lw $s4, 0($a1) # get templateBufferInfo --> templateBuffer --> Start address
        lw $s5, 4($a1) # get width
        mult $s5, $s0
        mflo $s5 # (width * row [j])
        addi $s5, $s5, 0 # ((width * row) + col), col is [0]
        sll $s5, $s5, 2 # multiply by 4 faster
        add $s4, $s4, $s5 # $s4 now has address of pixel T[0][j]
        lbu $t0, 0($s4) # $t0 now has the intensity of the pixel
        
        lw $s4, 0($a1) # get templateBufferInfo --> templateBuffer --> Start address
        lw $s5, 4($a1) # get width      
        mult $s5, $s0
        mflo $s5 # (width * row [j])
        addi $s5, $s5, 1 # ((width * row) + col)
        sll $s5, $s5, 2 # multiply by 4 faster
        add $s4, $s4, $s5 # $s4 now has address of pixel
        lbu $t1, 0($s4) # $t0 now has the intensity of the pixel
        
        lw $s4, 0($a1) # get templateBufferInfo --> templateBuffer --> Start address
        lw $s5, 4($a1) # get width    
        mult $s5, $s0
        mflo $s5 # (width * row [j])
        addi $s5, $s5, 2 # ((width * row) + col)
        sll $s5, $s5, 2 # multiply by 4 faster
        add $s4, $s4, $s5 # $s4 now has address of pixel
        lbu $t2, 0($s4) # $t0 now has the intensity of the pixel
        
        lw $s4, 0($a1) # get templateBufferInfo --> templateBuffer --> Start address
        lw $s5, 4($a1) # get width    
        mult $s5, $s0
        mflo $s5 # (width * row [j])
        addi $s5, $s5, 3 # ((width * row) + col)
        sll $s5, $s5, 2 # multiply by 4 faster
        add $s4, $s4, $s5 # $s4 now has address of pixel
        lbu $t3, 0($s4) # $t0 now has the intensity of the pixel
        
        lw $s4, 0($a1) # get templateBufferInfo --> templateBuffer --> Start address
        lw $s5, 4($a1) # get width    
        mult $s5, $s0
        mflo $s5 # (width * row [j])
        addi $s5, $s5, 4 # ((width * row) + col)
        sll $s5, $s5, 2 # multiply by 4 faster
        add $s4, $s4, $s5 # $s4 now has address of pixel
        lbu $t4, 0($s4) # $t0 now has the intensity of the pixel
        
        lw $s4, 0($a1) # get templateBufferInfo --> templateBuffer --> Start address
        lw $s5, 4($a1) # get width    
        mult $s5, $s0
        mflo $s5 # (width * row [j])
        addi $s5, $s5, 5 # ((width * row) + col)
        sll $s5, $s5, 2 # multiply by 4 faster
        add $s4, $s4, $s5 # $s4 now has address of pixel
        lbu $t5, 0($s4) # $t0 now has the intensity of the pixel
        
        lw $s4, 0($a1) # get templateBufferInfo --> templateBuffer --> Start address
        lw $s5, 4($a1) # get width    
        mult $s5, $s0
        mflo $s5 # (width * row [j])
        addi $s5, $s5, 6 # ((width * row) + col)
        sll $s5, $s5, 2 # multiply by 4 faster
        add $s4, $s4, $s5 # $s4 now has address of pixel
        lbu $t6, 0($s4) # $t0 now has the intensity of the pixel
        
        lw $s4, 0($a1) # get templateBufferInfo --> templateBuffer --> Start address
        lw $s5, 4($a1) # get width    
        mult $s5, $s0
        mflo $s5 # (width * row [j])
        addi $s5, $s5, 7 # ((width * row) + col)
        sll $s5, $s5, 2 # multiply by 4 faster
        add $s4, $s4, $s5 # $s4 now has address of pixel
        lbu $t7, 0($s4) # $t7 now has the intensity of the pixel
        
        #only important not to mess up t0 - t7 after this point
        
        FL2:
        lw $s3, 8($a0)
        subi $s3, $s3, 8
        bgt $s1, $s3, endFL2 #for ( int y = 0; y <= height - 8; y++ )
                
            FL3:
            lw $s3, 4($a0)
            subi $s3, $s3, 8
            bgt $s2, $s3, endFL3 #for (int x = 0; x <= width - 8; x++ )
        
                #Get pixel SAD[x][y] address
                lw $s4, 0($a2) # get errorBufferInfo --> errorBuffer --> Start address
                lw $s5, 4($a2) # get width
                mult $s5, $s1
                mflo $s5 # (width * row, assuming row is y)
                add $s5, $s5, $s2 # ((width * row) + col), assuming col is x
                sll $s5, $s5, 2 # multiply by 4 faster
                add $t9, $s4, $s5 # $t9 now has address of pixel SAD[x][y]
        
                #Intensity 0
                lw $s4, 0($a0) # get imageBufferInfo --> displayBuffer --> Start address
                add $s3, $s2, 0 # x+0
                add $s5, $s1, $s0 # y+j
                lw $s6, 4($a0) # get width
                mult $s6, $s5
                mflo $s6 # (width * row) row is y+j I'm guessing
                add $s6, $s6, $s3 # ((width * row) + col), col is x+0
                sll $s6, $s6, 2 # multiply by 4 faster
                add $s4, $s4, $s6 # $s4 now has address of pixel I[x+0][y+j]
                lbu $t8, 0($s4) # $t8 now has the intensity of the pixel stored at address $s4
                sub $t0, $t8, $t0 # I - T intensities determined
                abs $t0, $t0 #abs
                #Add it to SAD[x][y]
                lw $t8, 0($t9) # $t8 now has the value of SAD inside $t9 pixel
                add $t8, $t8, $t0 # append current value of SAD function to value stored in [x][y] pixel
                sw $t8, 0($t9) # store current SAD value to correct pixel
                
                #Intensity 1
                lw $s4, 0($a0) # get imageBufferInfo --> displayBuffer --> Start address
                add $s3, $s2, 1 # x+0
                add $s5, $s1, $s0 # y+j
                lw $s6, 4($a0) # get width
                mult $s6, $s5
                mflo $s6 # (width * row) row is y+j I'm guessing
                add $s6, $s6, $s3 # ((width * row) + col), col is x+0
                sll $s6, $s6, 2 # multiply by 4 faster
                add $s4, $s4, $s6 # $s4 now has address of pixel I[x+0][y+j]
                lbu $t8, 0($s4) # $t8 now has the intensity of the pixel stored at address $s4
                sub $t0, $t8, $t1 # I - T intensities determined
                abs $t0, $t0 #abs
                #Add it to SAD[x][y]
                lw $t8, 0($t9) # $t8 now has the value of SAD inside $t9 pixel
                add $t8, $t8, $t0 # append current value of SAD function to value stored in [x][y] pixel
                sw $t8, 0($t9) # store current SAD value to correct pixel
                
                #Intensity 2
                lw $s4, 0($a0) # get imageBufferInfo --> displayBuffer --> Start address
                add $s3, $s2, 2 # x+0
                add $s5, $s1, $s0 # y+j
                lw $s6, 4($a0) # get width
                mult $s6, $s5
                mflo $s6 # (width * row) row is y+j I'm guessing
                add $s6, $s6, $s3 # ((width * row) + col), col is x+0
                sll $s6, $s6, 2 # multiply by 4 faster
                add $s4, $s4, $s6 # $s4 now has address of pixel I[x+0][y+j]
                lbu $t8, 0($s4) # $t8 now has the intensity of the pixel stored at address $s4
                sub $t0, $t8, $t2 # I - T intensities determined
                abs $t0, $t0 #abs
                #Add it to SAD[x][y]
                lw $t8, 0($t9) # $t8 now has the value of SAD inside $t9 pixel
                add $t8, $t8, $t0 # append current value of SAD function to value stored in [x][y] pixel
                sw $t8, 0($t9) # store current SAD value to correct pixel
                
                #Intensity 3
                lw $s4, 0($a0) # get imageBufferInfo --> displayBuffer --> Start address
                add $s3, $s2, 3 # x+0
                add $s5, $s1, $s0 # y+j
                lw $s6, 4($a0) # get width
                mult $s6, $s5
                mflo $s6 # (width * row) row is y+j I'm guessing
                add $s6, $s6, $s3 # ((width * row) + col), col is x+0
                sll $s6, $s6, 2 # multiply by 4 faster
                add $s4, $s4, $s6 # $s4 now has address of pixel I[x+0][y+j]
                lbu $t8, 0($s4) # $t8 now has the intensity of the pixel stored at address $s4
                sub $t0, $t8, $t3 # I - T intensities determined
                abs $t0, $t0 #abs
                #Add it to SAD[x][y]
                lw $t8, 0($t9) # $t8 now has the value of SAD inside $t9 pixel
                add $t8, $t8, $t0 # append current value of SAD function to value stored in [x][y] pixel
                sw $t8, 0($t9) # store current SAD value to correct pixel
                
                #Intensity 4
                lw $s4, 0($a0) # get imageBufferInfo --> displayBuffer --> Start address
                add $s3, $s2, 4 # x+0
                add $s5, $s1, $s0 # y+j
                lw $s6, 4($a0) # get width
                mult $s6, $s5
                mflo $s6 # (width * row) row is y+j I'm guessing
                add $s6, $s6, $s3 # ((width * row) + col), col is x+0
                sll $s6, $s6, 2 # multiply by 4 faster
                add $s4, $s4, $s6 # $s4 now has address of pixel I[x+0][y+j]
                lbu $t8, 0($s4) # $t8 now has the intensity of the pixel stored at address $s4
                sub $t0, $t8, $t4 # I - T intensities determined
                abs $t0, $t0 #abs
                #Add it to SAD[x][y]
                lw $t8, 0($t9) # $t8 now has the value of SAD inside $t9 pixel
                add $t8, $t8, $t0 # append current value of SAD function to value stored in [x][y] pixel
                sw $t8, 0($t9) # store current SAD value to correct pixel
               
                #Intensity 5
                lw $s4, 0($a0) # get imageBufferInfo --> displayBuffer --> Start address
                add $s3, $s2, 5 # x+0
                add $s5, $s1, $s0 # y+j
                lw $s6, 4($a0) # get width
                mult $s6, $s5
                mflo $s6 # (width * row) row is y+j I'm guessing
                add $s6, $s6, $s3 # ((width * row) + col), col is x+0
                sll $s6, $s6, 2 # multiply by 4 faster
                add $s4, $s4, $s6 # $s4 now has address of pixel I[x+0][y+j]
                lbu $t8, 0($s4) # $t8 now has the intensity of the pixel stored at address $s4
                sub $t0, $t8, $t5 # I - T intensities determined
                abs $t0, $t0 #abs
                #Add it to SAD[x][y]
                lw $t8, 0($t9) # $t8 now has the value of SAD inside $t9 pixel
                add $t8, $t8, $t0 # append current value of SAD function to value stored in [x][y] pixel
                sw $t8, 0($t9) # store current SAD value to correct pixel
                
                #Intensity 6
                lw $s4, 0($a0) # get imageBufferInfo --> displayBuffer --> Start address
                add $s3, $s2, 6 # x+0
                add $s5, $s1, $s0 # y+j
                lw $s6, 4($a0) # get width
                mult $s6, $s5
                mflo $s6 # (width * row) row is y+j I'm guessing
                add $s6, $s6, $s3 # ((width * row) + col), col is x+0
                sll $s6, $s6, 2 # multiply by 4 faster
                add $s4, $s4, $s6 # $s4 now has address of pixel I[x+0][y+j]
                lbu $t8, 0($s4) # $t8 now has the intensity of the pixel stored at address $s4
                sub $t0, $t8, $t6 # I - T intensities determined
                abs $t0, $t0 #abs
                #Add it to SAD[x][y]
                lw $t8, 0($t9) # $t8 now has the value of SAD inside $t9 pixel
                add $t8, $t8, $t0 # append current value of SAD function to value stored in [x][y] pixel
                sw $t8, 0($t9) # store current SAD value to correct pixel
                
                #Intensity 7
                lw $s4, 0($a0) # get imageBufferInfo --> displayBuffer --> Start address
                add $s3, $s2, 7 # x+0
                add $s5, $s1, $s0 # y+j
                lw $s6, 4($a0) # get width
                mult $s6, $s5
                mflo $s6 # (width * row) row is y+j I'm guessing
                add $s6, $s6, $s3 # ((width * row) + col), col is x+0
                sll $s6, $s6, 2 # multiply by 4 faster
                add $s4, $s4, $s6 # $s4 now has address of pixel I[x+0][y+j]
                lbu $t8, 0($s4) # $t8 now has the intensity of the pixel stored at address $s4
                sub $t0, $t8, $t7 # I - T intensities determined
                abs $t0, $t0 #abs
                #Add it to SAD[x][y]
                lw $t8, 0($t9) # $t8 now has the value of SAD inside $t9 pixel
                add $t8, $t8, $t0 # append current value of SAD function to value stored in [x][y] pixel
                sw $t8, 0($t9) # store current SAD value to correct pixel
        
            addi $s2, $s2, 1
            j FL3
            endFL3:
            #set x back to 0
            li $s2, 0
 
        addi $s1, $s1, 1
        j FL2
        endFL2:
        #set y back to 0
        li $s1, 0
        
    addi $s0, $s0, 1
    j FL1
    endFL1:

        lw $s6, 0($sp)
        addi $sp, $sp, 4
                        
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
        
        lw $ra, 0($sp)
        addi $sp, $sp, 4
	jr $ra	

	
###############################################################
# loadImage( bufferInfo* imageBufferInfo )
# NOTE: struct bufferInfo { int *buffer, int width, int height, char* filename }
loadImage:	lw $a3, 0($a0)  # int* buffer
		lw $a1, 4($a0)  # int width
		lw $a2, 8($a0)  # int height
		lw $a0, 12($a0) # char* filename
		mul $t0, $a1, $a2 # words to read (width x height) in a2
		sll $t0, $t0, 2	  # multiply by 4 to get bytes to read
		li $a1, 0     # flags (0: read, 1: write)
		li $a2, 0     # mode (unused)
		li $v0, 13    # open file, $a0 is null-terminated string of file name
		syscall
		move $a0, $v0     # file descriptor (negative if error) as argument for read
  		move $a1, $a3     # address of buffer to which to write
		move $a2, $t0	  # number of bytes to read
		li  $v0, 14       # system call for read from file
		syscall           # read from file
        		# $v0 contains number of characters read (0 if end-of-file, negative if error).
        		# We'll assume that we do not need to be checking for errors!
		# Note, the bitmap display doesn't update properly on load, 
		# so let's go touch each memory address to refresh it!
		move $t0, $a3	   # start address
		add $t1, $a3, $a2  # end address
loadloop:	lw $t2, ($t0)
		sw $t2, ($t0)
		addi $t0, $t0, 4
		bne $t0, $t1, loadloop
		jr $ra
		
		
#####################################################
# (offset, score) = findBest( bufferInfo errorBuffer )
# Returns the address offset and score of the best match in the error Buffer
findBest:	lw $t0, 0($a0)     # load error buffer start address	
		lw $t2, 4($a0)	   # load width
		lw $t3, 8($a0)	   # load height
		addi $t3, $t3, -7  # height less 8 template lines minus one
		mul $t1, $t2, $t3
		sll $t1, $t1, 2    # error buffer size in bytes	
		add $t1, $t0, $t1  # error buffer end address
		li $v0, 0		# address of best match	
		li $v1, 0xffffffff 	# score of best match	
		lw $a1, 4($a0)    # load width
        		addi $a1, $a1, -7 # initialize column count to 7 less than width to account for template
fbLoop:		lw $t9, 0($t0)        # score
		sltu $t8, $t9, $v1    # better than best so far?
		beq $t8, $zero, notBest
		move $v0, $t0
		move $v1, $t9
notBest:		addi $a1, $a1, -1
		bne $a1, $0, fbNotEOL # Need to skip 8 pixels at the end of each line
		lw $a1, 4($a0)        # load width
        		addi $a1, $a1, -7     # column count for next line is 7 less than width
        		addi $t0, $t0, 28     # skip pointer to end of line (7 pixels x 4 bytes)
fbNotEOL:	add $t0, $t0, 4
		bne $t0, $t1, fbLoop
		lw $t0, 0($a0)     # load error buffer start address	
		sub $v0, $v0, $t0  # return the offset rather than the address
		jr $ra
		

#####################################################
# highlight( bufferInfo imageBuffer, int offset )
# Applies green mask on all pixels in an 8x8 region
# starting at the provided addr.
highlight:	lw $t0, 0($a0)     # load image buffer start address
		add $a1, $a1, $t0  # add start address to offset
		lw $t0, 4($a0) 	# width
		sll $t0, $t0, 2	
		li $a2, 0xff00 	# highlight green
		li $t9, 8	# loop over rows
highlightLoop:	lw $t3, 0($a1)		# inner loop completely unrolled	
		and $t3, $t3, $a2
		sw $t3, 0($a1)
		lw $t3, 4($a1)
		and $t3, $t3, $a2
		sw $t3, 4($a1)
		lw $t3, 8($a1)
		and $t3, $t3, $a2
		sw $t3, 8($a1)
		lw $t3, 12($a1)
		and $t3, $t3, $a2
		sw $t3, 12($a1)
		lw $t3, 16($a1)
		and $t3, $t3, $a2
		sw $t3, 16($a1)
		lw $t3, 20($a1)
		and $t3, $t3, $a2
		sw $t3, 20($a1)
		lw $t3, 24($a1)
		and $t3, $t3, $a2
		sw $t3, 24($a1)
		lw $t3, 28($a1)
		and $t3, $t3, $a2
		sw $t3, 28($a1)
		add $a1, $a1, $t0	# increment address to next row	
		add $t9, $t9, -1		# decrement row count
		bne $t9, $zero, highlightLoop
		jr $ra

######################################################
# processError( bufferInfo error )
# Remaps scores in the entire error buffer. The best score, zero, 
# will be bright green (0xff), and errors bigger than 0x4000 will
# be black.  This is done by shifting the error by 5 bits, clamping
# anything bigger than 0xff and then subtracting this from 0xff.
processError:	lw $t0, 0($a0)     # load error buffer start address
		lw $t2, 4($a0)	   # load width
		lw $t3, 8($a0)	   # load height
		addi $t3, $t3, -7  # height less 8 template lines minus one
		mul $t1, $t2, $t3
		sll $t1, $t1, 2    # error buffer size in bytes	
		add $t1, $t0, $t1  # error buffer end address
		lw $a1, 4($a0)     # load width as column counter
        		addi $a1, $a1, -7  # initialize column count to 7 less than width to account for template
pebLoop:		lw $v0, 0($t0)        # score
		srl $v0, $v0, 5       # reduce magnitude 
		slti $t2, $v0, 0x100  # clamp?
		bne  $t2, $zero, skipClamp
		li $v0, 0xff          # clamp!
skipClamp:	li $t2, 0xff	      # invert to make a score
		sub $v0, $t2, $v0
		sll $v0, $v0, 8       # shift it up into the green
		sw $v0, 0($t0)
		addi $a1, $a1, -1        # decrement column counter	
		bne $a1, $0, pebNotEOL   # Need to skip 8 pixels at the end of each line
		lw $a1, 4($a0)        # load width to reset column counter
        		addi $a1, $a1, -7     # column count for next line is 7 less than width
        		addi $t0, $t0, 28     # skip pointer to end of line (7 pixels x 4 bytes)
pebNotEOL:	add $t0, $t0, 4
		bne $t0, $t1, pebLoop
		jr $ra
