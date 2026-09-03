


.text

.equ SCREEN_W, 32
.equ SCREEN_H, 60
.equ SCREEN_PIXELS, 1920 ; SCREEN_W * SCREEN_H
.equ LINE_H, 5
.equ WORD_SIZE, 16

.equ PIXELS_BETWEEN_CHARS, 1
.equ PIXELS_BETWEEN_LINES, 1

program_start:

write_chars:
        LDI r0, 0 ; char_index = 0
        LDI r9, 0 ; offset_pixel_x = 0
        LDI r10, 0 ; offset_pixel_y = 0
        
write_char:
        ; Load character
        LDI  r1, char_buffer
        ADD  r1, r1, r0
        LOAD r1, [r1]

        ; If char = 0, end program
        LDI r15, 0
        CMP r1,  r15
        LDI r15, write_frame_buffer
        JMP EQ,  r15

        ; Load character index from ascii table
        LDI r15, ascii_table
        ADD r15, r15, r1
        LOAD r1, [r15]

        ; Get the address for the character definition
        LDI  r2, l_index
        ADD  r2, r2, r1
        LOAD r2, [r2]

        ; Get the character width
        LDI  r3, l_width
        ADD  r3, r3, r1
        LOAD r3, [r3]

        ; Check if the next pixel should be written to the next line
        ADD r14, r9,           r3 ; next_pixel_x = offset_pixel_x + char_width
        LDI r15, SCREEN_W
        CMP r14, r15              ; next_pixel_x - SCREEN_W
        LDI r15, pixel_if_end
        JMP NEG, r15
        JMP EQ,  r15

        LDI r9,  0                         ; offset_pixel_x = 0
        LDI r15, LINE_H
        ADD r10, r10,                  r15 ; offset_pixel_y += LINE_H
        LDI r15, PIXELS_BETWEEN_LINES
        ADD r10, r10,                  r15 ; offset_pixel_y += PIXELS_BETWEEN_LINES

pixel_if_end:
        LDI  r4, 0                       ; i = 0
        LDI  r8, frame_word_buffer_addr
        LOAD r8, [r8]                    ; buffer_addr = frame_word_buffer

        LDI r5, 0 ; y = 0
loop_y:
            NOP
            LDI r6, 0 ; x = 0
loop_x:
                NOP
                
                MOV r7,  r2
                ADD r7,  r7,   r4 ; cell_addr = char_addr + i
                LOAD r7, [r7]     ; cell_set = *cell_addr

                ADD r12, r6, r9  ; pixel_x = x + offset_pixel_x
                ADD r13, r5, r10 ; pixel_y = y + offset_pixel_y

                ; pixel_y * SCREEN_W
                ; Sadly, I did not implement a multiply instruction in the CPU
                ; And implementing a new for loop would take too much instructions for now.
                ; 
                ; As SCREEN_W is set to 32 (for now), we can just shift the
                ; to the left 5 bits as a workaround. Which is the same as multiplying by 32.
                ; Example:
                ; SCREEN_W = 32
                ; pixel_y = 5
                ; result = pixel_y * SCREEN_W = 160
                ; result = pixel_y << 5 (shift to left 5 bits) = 160
                ;
                ; Note: for this to work SCREEN_W must be multiple of two
                ; When SCREEN_W changes the amount of ADD r13, r13, r13 needs to change
                ; according to: log2(SCREEN_W)
                ; 
                ADD r13, r13, r13
                ADD r13, r13, r13
                ADD r13, r13, r13
                ADD r13, r13, r13
                ADD r13, r13, r13

                ADD r12, r12, r13 ; pixel_index = pixel_x + pixel_y * SCREEN_W
                ADD r12, r8,  r12 ; pixel_addr = buffer_addr + pixel_index

                STORE [r12], r7 ; *pixel_addr = cell_set

                ADDI r4,  1      ; i += 1
                ADDI r6,  1      ; x += 1
                CMP  r3,  r6     ; char_width - x
                LDI  r15, loop_x
                JMP  POS, r15    ; x > 0

            ADDI r5,  1       ; y += 1
            LDI  r15, LINE_H
            CMP  r15, r5      ; LINE_H - y
            LDI  r15, loop_y
            JMP  POS, r15     ; y > 0

        LDI  r15, PIXELS_BETWEEN_CHARS
        ADD  r9,     r9,         r15 ; offset_pixel_x += PIXELS_BETWEEN_CHARS
        ADD  r9,     r9,         r3  ; offset_pixel_x += char_width
        ADDI r0,     1               ; char_index += 1
        LDI  r15,    write_char
        JMP  ALWAYS, r15

write_frame_buffer:
        ; Now that the word frame buffer has been filled, we need to convert it to an actual frame buffer
        ; The frame buffer has 1 bit per pixel.
        ; So here we convert 1 word per pixel to 1 bit per pixel.

        LDI  r0, 0                 ; frame_buffer_index = 0
        LDI  r1, frame_buffer_addr
        LOAD r1, [r1]              ; frame_buffer_addr

        LDI  r2, 0                       ; word_buffer_index = 0
        LDI  r3, frame_word_buffer_addr
        LOAD r3, [r3]                    ; word_buffer_addr

        LDI r4, 0 ; word_bit_index = 0
        LDI r5, 0 ; word_value = 0

        LDI r6, 0

loop_word_pixel:
        NOP

if_word_start:
        LDI r15, WORD_SIZE
        CMP r15, r4
        LDI r15, if_word_end
        JMP NEQ, r15

        ADD   r7,   r1, r0
        STORE [r7], r5

        LDI  r5, 0 ; word_value = 0
        LDI  r4, 0 ; word_bit_index = 0
        ADDI r0, 1
if_word_end:

        ; word_value += *(word_buffer_addr + word_buffer_index)
        ADD r5, r5, r5 ; word_value << 1
       
        ADD  r6, r3,  r2
        LOAD r6, [r6]
        ADD  r5, r5,  r6


        ADDI r2, 1 ; word_buffer_index += 1
        ADDI r4, 1 ; word_bit_index += 1

        LDI  r15, screen_pixels_data
        LOAD r15, [r15]
        CMP  r15, r2                 ; SCREEN_PIXELS - word_buffer_index
        LDI  r15, loop_word_pixel
        JMP  POS, r15

program_end:
        HALT

.data

screen_pixels_data:.word SCREEN_PIXELS

char_buffer:
.word 'h','a','l','l','o',' '
.word 'i','k',' ','b','e','n'
.word 's','t','i','j','n',0

frame_buffer_addr:.word frame_buffer
frame_word_buffer_addr:.word frame_word_buffer

.org 200

; Charachter widths
l_width:.word   4,  4,  4,  4,  4,  4,  4,  4,  1,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  3,  4,  3,  5,  4,  3,  4,      3
l_index:.word l_a,l_b,l_c,l_d,l_e,l_f,l_g,l_h,l_i,l_j,l_k,l_l,l_m,l_n,l_o,l_p,l_q,l_r,l_s,l_t,l_u,l_v,l_w,l_x,l_y,l_z,l_space

ascii_table:
.word 0,0,0,0
.word 0,0,0,0
.word 0,0,0,0
.word 0,0,0,0
.word 0,0,0,0
.word 0,0,0,0
.word 0,0,0,0
.word 0,0,0,0
.word 26,0,0,0
.word 0,0,0,0
.word 0,0,0,0
.word 0,0,0,0
.word 0,0,0,0
.word 0,0,0,0
.word 0,0,0,0
.word 0,0,0,0
.word 0,0,1,2
.word 3,4,5,6
.word 7,8,9,10
.word 11,12,13,14
.word 15,16,17,18
.word 19,20,21,22
.word 23,24,25,0
.word 0,0,0,0
.word 0,0,1,2
.word 3,4,5,6
.word 7,8,9,10
.word 11,12,13,14
.word 15,16,17,18
.word 19,20,21,22
.word 23,24,25,0
.word 0,0,0,0

; Space
l_space:
.word 0,0,0
.word 0,0,0
.word 0,0,0
.word 0,0,0
.word 0,0,0

; A
l_a:
.word 0,1,1,0
.word 1,0,0,1
.word 1,0,0,1
.word 1,1,1,1
.word 1,0,0,1

; B
l_b:
.word 1,1,1,0
.word 1,0,0,1
.word 1,1,1,0
.word 1,0,0,1
.word 1,1,1,0

; C
l_c:
.word 1,1,1,1
.word 1,0,0,0
.word 1,0,0,0
.word 1,0,0,0
.word 1,1,1,1

; D
l_d:
.word 1,1,1,0
.word 1,0,0,1
.word 1,0,0,1
.word 1,0,0,1
.word 1,1,1,0

; E
l_e:
.word 1,1,1,1
.word 1,0,0,0
.word 1,1,1,1
.word 1,0,0,0
.word 1,1,1,1

; F
l_f:
.word 1,1,1,1
.word 1,0,0,0
.word 1,1,1,0
.word 1,0,0,0
.word 1,0,0,0

; G
l_g:
.word 0,1,1,1
.word 1,0,0,0
.word 1,0,1,1
.word 1,0,0,1
.word 0,1,1,1

; H
l_h:
.word 1,0,0,1
.word 1,0,0,1
.word 1,1,1,1
.word 1,0,0,1
.word 1,0,0,1

; I
l_i:
.word 1
.word 1
.word 1
.word 1
.word 1

; J
l_j:
.word 0,0,0,1
.word 0,0,0,1
.word 0,0,0,1
.word 1,0,0,1
.word 0,1,1,0

; K
l_k:
.word 1,0,0,1
.word 1,0,1,0
.word 1,1,0,0
.word 1,0,1,0
.word 1,0,0,1

; L
l_l:
.word 1,0,0,0
.word 1,0,0,0
.word 1,0,0,0
.word 1,0,0,0
.word 1,1,1,1

; M
l_m:
.word 1,0,0,1
.word 1,1,1,1
.word 1,0,0,1
.word 1,0,0,1
.word 1,0,0,1


; N
l_n:
.word 1,0,0,1
.word 1,1,0,1
.word 1,0,1,1
.word 1,0,0,1
.word 1,0,0,1

; O
l_o:
.word 0,1,1,0
.word 1,0,0,1
.word 1,0,0,1
.word 1,0,0,1
.word 0,1,1,0

; P
l_p:
.word 0,1,1,0
.word 1,0,0,1
.word 1,1,1,0
.word 1,0,0,0
.word 0,0,0,0

; Q
l_q:
.word 0,1,1,0
.word 1,0,0,1
.word 1,0,0,1
.word 1,0,1,1
.word 0,1,1,0

; R
l_r:
.word 0,1,1,0
.word 1,0,0,1
.word 1,1,1,0
.word 1,0,1,0
.word 1,0,0,1

; S
l_s:
.word 0,1,1,1
.word 1,0,0,0
.word 0,1,1,1
.word 0,0,0,1
.word 1,1,1,0

; T
l_t:
.word 1,1,1
.word 0,1,0
.word 0,1,0
.word 0,1,0
.word 0,1,0

; U
l_u:
.word 1,0,0,1
.word 1,0,0,1
.word 1,0,0,1
.word 1,0,0,1
.word 0,1,1,0

; V
l_v:
.word 1,0,1
.word 1,0,1
.word 1,0,1
.word 1,0,1
.word 0,1,0

; W
l_w:
.word 1,0,1,0,1
.word 1,0,1,0,1
.word 1,0,1,0,1
.word 1,0,1,0,1
.word 0,1,0,1,0

; X
l_x:
.word 1,0,0,1
.word 0,1,1,0
.word 0,1,1,0
.word 1,0,0,1
.word 1,0,0,1

; Y
l_y:
.word 1,0,1
.word 1,0,1
.word 0,1,0
.word 0,1,0
.word 0,1,0

; Z
l_z:
.word 1,1,1,1
.word 0,0,0,1
.word 0,0,1,0
.word 0,1,0,0
.word 1,1,1,1

.org 1500
frame_buffer:.word 0

.org 2000
frame_word_buffer:.word 0
