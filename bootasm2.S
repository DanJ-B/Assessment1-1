# Second stage of the boot loader

.code16                         # Assemble for 16-bit mode
.globl start
start:
    jmp     real_start

# Write to the console using BIOS.
# 
# Input: SI contains the address of the null-terminated string to be displayed

cons_write:
    movb    $0x0e, %ah           # 0x0e is the INT 10h BIOS call to output the value contained in AL to screen

cons_write_rpt:
    movb    (%si), %al          # Load the byte at the location contained in the SI register into AL   
    inc     %si                 # Add 1 to the value in SI
    cmp     $0, %al             # Compare the value in AL with 0
    jz      cons_write_done     # If it is zero, then we are done
    int     $0x10               # Output the character in AL to the screen
    jmp     cons_write_rpt      # and continue

cons_write_done:                # Something that is called will never return 
    ret                         # until a 'ret' instruction is encountered.  Labels do 
                                # not give a program any structure.  They just give a 
                                # memory location a name that we can use in our code. 

cons_write_crlf:
    movb    $0x0e, %ah          # Output CR
    movb    $0x0d, %al
    int     $0x10
    movb    $0x0a, %al          # Output LF
    int     $0x10
    ret

cons_writeline:
    call    cons_write
    call    cons_write_crlf
    ret   

 draw_line:
    movw    %ax, (x0_position)    # Line drawing algortihm
    movb    %bh, (y0_position)
    movw    %cx, (x1_position)
    movb    %bl, (y1_position)      
    movb    %dl, colour
    subw    %ax, %cx            # dx = abs(x1-x0)
    movw    %cx, deltaX         # %cx = x1-x0                
    movw    y0_position, %ax    
    movw    y1_position, %dx 
    sub     %ax, %dx            # dy = abs(y1-y0)
    movw    %dx, deltaY         # %dx = y1-y0
    compare_x:
    cmp     $0, %cx             # ensure dx is not negative
    jl      error_handle_x 
    movw    %cx, deltaX     
    jmp     compare_y
    error_handle_x:
    neg     %cx
    movw    %cx, deltaX         # if dx is negative, flip sign
    compare_y:
    cmp     $0, %dx             # ensure dy is not negative
    jl      error_handle_y  
    movw    %dx, deltaY 
    jmp     xdirection_alloc
    error_handle_y:
    neg     %dx
    movw    %dx, deltaY         # if dy is negative, flip sign
    xdirection_alloc:
    movw    (x0_position), %ax
    cmp     (x1_position), %ax    # ax = x0 position so compare x1 to x0
    jl      x_direction         # if x0 < x1, sx = 1
    movw    $-1, sx             # else sx = -1
    jmp     ydirection_alloc
    x_direction:
    movw    $1, sx
    ydirection_alloc:
    movw    (y0_position), %bx
    cmp     (y1_position), %bx    # bx = y0 position so compare y1 to y0
    jl      y_direction         # if y0 < y1, sy = 1
    movw    $-1, sy             # else sy = -1
    jmp     plot_pixel
    y_direction:
    movw    $1, sy 
    movw    deltaX, %cx
    movw    deltaY, %dx
    sub     %dx, %cx            # err = dx - dy (into %dx register) 
    movw    %cx, err 

plot_pixel:
    movb    $0x0C, %ah
    movb    colour, %al
    movb    $0, %bh
    movw    (x0_position), %cx    # set pixels x0 and y0
    movw    (y0_position), %dx
    int     $0x10
    cmp     (x1_position), %cx    # cx = x0 position
    je      condition_met       # if x0 = x1, check is y0 = y1
    jmp     next                # if not, go to "next"

    condition_met:
    cmp     (y1_position), %dx    # bx = y0 position
    je      exit                # if y0 = y1, the line is drawn 

    next:
    movw    err, %ax            # store err in %ax
    movw    $2, %bx                        
    mul     %bx                 # multiply %ax and %bx, (e2 = 2 * err)
    movw    %ax, e2             # store result in e2
    movw    deltaY, %ax
    neg     %ax                 # get -dy value
    cmp     %ax, e2             
    jg      line_106            # if e2 > -dy, 
    jmp     line_110            # else go to line 110

    line_106:
    movw    deltaY, %ax
    sub     %ax, err            # err = err - dy
    movw    sx, %ax             
    add     %ax, (x0_position)    # x0 = x0 + sx

    line_110:
    movw    deltaX, %ax         # get dx value
    cmp     %ax, e2             
    jl      line_114            # if e2 < dx
    jmp     line_119
    line_114:
    movw    deltaX, %ax
    add     %ax, err            # err = err + dx
    movw    sy, %ax             # store sy in %ax
    add     %ax, (y0_position)    # y0 = y0 + sy
    line_119:
    jmp     plot_pixel

exit:
    ret

real_start:
    movw    $boot_message, %si  # Display our boot message
    call    cons_writeline
    movb    $0, %ah
    movb    $0x13, %al          # VGA interrupt
    int     $0x10               # Calls VGA interrupt
    line1:
    movb    $0, %dl
    movw     $0, %ax
    movb     $0, %bh
    movw     $10, %cx
    movb     $199, %bl
    call    draw_line
    line2:
    movb    $1, %dl
    movw     $0, %ax
    movb     $10, %bh
    movw     $20, %cx
    movb     $199, %bl
    call    draw_line
    line3:
    movb    $2, %dl
    movw     $0, %ax
    movb     $30, %bh
    movw     $40, %cx
    movb     $199, %bl
    call    draw_line
    line4:
    movb    $3, %dl
    movw     $0, %ax
    movb     $40, %bh
    movw     $60, %cx
    movb     $199, %bl
    call    draw_line
    line5:
    movb    $4, %dl
    movw     $0, %ax
    movb     $50, %bh
    movw     $80, %cx
    movb     $199, %bl
    call    draw_line
    line6:
    movb    $5, %dl
    movw     $0, %ax
    movb     $60, %bh
    movw     $100, %cx
    movb     $199, %bl
    call    draw_line
    line7:
    movb    $6, %dl
    movw     $0, %ax
    movb     $70, %bh
    movw     $120, %cx
    movb     $199, %bl
    call    draw_line
    line8:
    movb    $7, %dl
    movw     $0, %ax
    movb     $80, %bh
    movw     $140, %cx
    movb     $199, %bl
    call    draw_line
    line9:
    movb    $8, %dl
    movw     $0, %ax
    movb     $90, %bh
    movw     $160, %cx
    movb     $199, %bl
    call    draw_line
    line10:
    movb    $9, %dl
    movw     $0, %ax
    movb     $100, %bh
    movw     $180, %cx
    movb     $199, %bl
    call    draw_line
    line11:
    movb    $10, %dl
    movw     $0, %ax
    movb     $110, %bh
    movw     $200, %cx
    movb     $199, %bl
    call    draw_line
    line12:
    movb    $11, %dl
    movw     $0, %ax
    movb     $120, %bh
    movw     $220, %cx
    movb     $199, %bl
    call    draw_line
    line13:
    movb    $12, %dl
    movw     $0, %ax
    movb     $130, %bh
    movw     $240, %cx
    movb     $199, %bl
    call    draw_line
    line14:
    movb    $13, %dl
    movw     $0, %ax
    movb     $140, %bh
    movw     $260, %cx
    movb     $199, %bl
    call    draw_line
    line15:
    movb    $14, %dl
    movw     $0, %ax
    movb     $150, %bh
    movw     $280, %cx
    movb     $199, %bl
    call    draw_line
    line16:
    movb    $15, %dl
    movw     $0, %ax
    movb     $160, %bh
    movw     $300, %cx
    movb     $199, %bl
    call    draw_line
    line17:
    movb    $1, %dl
    movw     $0, %ax
    movb     $170, %bh
    movw     $300, %cx
    movb     $199, %bl
    call    draw_line
    line18:
    movb    $2, %dl
    movw     $0, %ax
    movb     $180, %bh
    movw     $319, %cx
    movb     $199, %bl
    call    draw_line

endless_loop:                   # Loop forever more
    jmp     endless_loop    

# Program data

boot_message:     
    .string "Boot Loader Stage 2 loaded"             

colour:
    .byte 0
x0_position:
    .word 0
y0_position:
    .word 0
x1_position:
    .word 0
y1_position:
    .word 0
sx:
    .word 0
sy:
    .word 0
err:
    .word 0
e2:
    .word 0 
deltaX:
    .word 0
deltaY:
    .word 0