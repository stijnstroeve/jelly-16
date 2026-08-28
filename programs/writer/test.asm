


.text

; .equ MAX_OFFSET, 4
; .equ WORD_SIZE, 16
; .equ FRAME_BUFFER_OFF, 128
; .equ CHAR_GRID_WIDTH, 10
; .equ CHAR_GRID_MAX_HEIGHT, 20

; buffer_addr = 1000
; screen_w = 32
; screen_h = 60
; line_h = 5
.equ SCREEN_W, 32
.equ SCREEN_H, 60
.equ LINE_H, 5

; .equ FRAME_BUFFER_SIZE

;         LDI r1, 0 ; Read offset
;         LDI r2, 0 ; Value

;         LDI r12, l_index
; loop:
;         LOAD r3, [r1] ; Load data
;         ADD r2, r2, r2 ; Shift bit to the left by 1
;         ADD r2, r2, r3 ; Add value to r2
;         ADDI r1, 1 ; Add 1 to address

;         LDI r15, MAX_OFFSET
;         CMP r1, r15 ; Compare offset to max offset
;         LDI r15, loop
;         JMP NEQ, r15

program_start:
        LDI r0, 0 ; Char index
        
        ; Load character
        LDI r1, char_buffer
        ADD r1, r1, r0
        LOAD r1, [r1]

        ; Subtract 97 (ascii a) to get the index of the letter
        LDI r15, 97
        SUB r1, r1, r15 ; We don't need the character itself anymore so we can overwrite it

        ; Get the address for the character definition
        LDI r2, l_index
        ADD r2, r2, r1
        LOAD r2, [r2]

        ; Get the character width
        LDI r3, l_width
        ADD r3, r3, r1
        LOAD r3, [r3]

        LDI r4, 0 ; i = 0
        LDI r5, 0 ; y = 0
loop_y:
            NOP
            LDI r6, 0 ; x = 0
loop_x:
                NOP
                
                ADDI r6, 1
                CMP r3, r6 ; char_width - x
                LDI r15, loop_x
                JMP POS, r15 ; x > 0

            ADDI r5, 1
            LDI r15, LINE_H
            CMP r15, r5 ; LINE_H - y
            LDI r15, loop_y
            JMP POS, r15 ; y > 0

; loop_x:
;                 LDI r6, 0 ; x = 0


;                 ADDI r4, 1 ; i += 1
                

program_end:
        HALT



.data

char_buffer:.word 'h','a','l','l','o',0

.org 100

; Charachter widths
l_width:.word 4,4,4,4,4,4,4,4,1,4,4,4,4,4,4,4,4,4,4,3,4,3,5,4,3,4

l_index:.word l_a,l_b,l_c,l_d,l_e,l_f,l_g,l_h,l_i,l_j,l_k,l_l,l_n,l_m,l_n,l_o,l_p,l_q,l_r,l_s,l_t,l_u,l_v,l_w,l_x,l_y,l_z

; .word 'H','a','l','l','o'

; .org 1000

; A
l_a:.word 0,1,1,0
.word 1,0,0,1
.word 1,0,0,1
.word 1,1,1,1
.word 1,0,0,1

; .word 'a','a','a','a'

; .word 0,1,1,0,0,0,1,1,0,0,0,1,1,0,0,0,1,1,0,0
; .word 1,0,0,1,0,1,0,0,1,0,1,0,0,1,0,1,0,0,1,0
; .word 1,0,0,1,0,1,0,0,1,0,1,0,0,1,0,1,0,0,1,0
; .word 1,1,1,1,0,1,1,1,1,0,1,1,1,1,0,1,1,1,1,0
; .word 1,0,0,1,0 1,0,0,1,0,1,0,0,1,0 1,0,0,1,0

; .word 0b0110001100011000, 0b1100100101001010, 0b0101001010010100, 0b1010010100101111, 0b0111101111011110, 0b1001010010100101, 0b0010000000000000

; .word 0b

; B
l_b:.word 1,1,1,0
.word 1,0,0,1
.word 1,1,1,0
.word 1,0,0,1
.word 1,1,1,0

; C
l_c:.word 1,1,1,1
.word 1,0,0,0
.word 1,0,0,0
.word 1,0,0,0
.word 1,1,1,1

; D
l_d:.word 1,1,1,0
.word 1,0,0,1
.word 1,0,0,1
.word 1,0,0,1
.word 1,1,1,0

; E
l_e:.word 1,1,1,1
.word 1,0,0,0
.word 1,1,1,1
.word 1,0,0,0
.word 1,1,1,1

; F
l_f:.word 1,1,1,1
.word 1,0,0,0
.word 1,1,1,0
.word 1,0,0,0
.word 1,0,0,0

; G
l_g:.word 0,1,1,1
.word 1,0,0,0
.word 1,0,1,1
.word 1,0,0,1
.word 0,1,1,1

; Pseudo
; buffer_addr = 1000
; screen_w = 32
; screen_h = 60
; line_h = 5

; offset_pixel_x = 0
; offset_pixel_y = 0

; 
; for char in chars
    ; char = 'a' = 97
    ; char_alfabetical_index = char - 97
    ; char_addr_addr = l_index + char_alfabetical_index
    ; char_addr = READ char_addr_addr
    ; char_width_addr = l_width + char_alfabetical_index
    ; char_width = READ char_width_addr
    ; 
    ; i = 0
    ; for y < line_h
    ;   for x < char_width
    ;       char_pixel_set = LOAD char_addr + i
    ;       buffer_x = x + offset_pixel_x
    ;       buffer_y = y + offset_pixel_y
    ;       buffer_index = buffer_x + buffer_y * screen_w
    ;       memory_addr = buffer_addr + buffer_index
    ;       STORE memory_addr, char_pixel_set
    ;       i += 1
    ;
    ; offset_pixel_x += char_width
    ; if offset_pixel_x > screen_w
    ;    offset_pixel_x = 0
    ;    offset_pixel_y += line_h
    ;    offset_pixel_y += 1

; H
l_h:.word 1,0,0,1
.word 1,0,0,1
.word 1,1,1,1
.word 1,0,0,1
.word 1,0,0,1

; I
l_i:.word 1
.word 1
.word 1
.word 1
.word 1

; J
l_j:.word 0,0,0,1
.word 0,0,0,1
.word 0,0,0,1
.word 1,0,0,1
.word 0,1,1,0

; K
l_k:.word 1,0,0,1
.word 1,0,1,0
.word 1,1,0,0
.word 1,0,1,0
.word 1,0,0,1

; L
l_l:.word 1,0,0,0
.word 1,0,0,0
.word 1,0,0,0
.word 1,0,0,0
.word 1,1,1,1

; M
l_m:.word 1,0,0,1
.word 1,1,1,1
.word 1,0,0,1
.word 1,0,0,1
.word 1,0,0,1


; N
l_n:.word 1,0,0,1
.word 1,1,0,1
.word 1,0,1,1
.word 1,0,0,1
.word 1,0,0,1

; O
l_o:.word 0,1,1,0
.word 1,0,0,1
.word 1,0,0,1
.word 1,0,0,1
.word 0,1,1,0

; P
l_p:.word 0,1,1,0
.word 1,0,0,1
.word 1,1,1,0
.word 1,0,0,0
.word 0,0,0,0

; Q
l_q:.word 0,1,1,0
.word 1,0,0,1
.word 1,0,0,1
.word 1,0,1,1
.word 0,1,1,0

; R
l_r:.word 0,1,1,0
.word 1,0,0,1
.word 1,1,1,0
.word 1,0,1,0
.word 1,0,0,1

; S
l_s:.word 0,1,1,1
.word 1,0,0,0
.word 0,1,1,1
.word 0,0,0,1
.word 1,1,1,0

; T
l_t:.word 1,1,1
.word 0,1,0
.word 0,1,0
.word 0,1,0
.word 0,1,0

; U
l_u:.word 1,0,0,1
.word 1,0,0,1
.word 1,0,0,1
.word 1,0,0,1
.word 0,1,1,0

; V
l_v:.word 1,0,1
.word 1,0,1
.word 1,0,1
.word 1,0,1
.word 0,1,0

; W
l_w:.word 1,0,1,0,1
.word 1,0,1,0,1
.word 1,0,1,0,1
.word 1,0,1,0,1
.word 0,1,0,1,0

; X
l_x:.word 1,0,0,1
.word 0,1,1,0
.word 0,1,1,0
.word 1,0,0,1
.word 1,0,0,1

; Y
l_y:.word 1,0,1
.word 1,0,1
.word 0,1,0
.word 0,1,0
.word 0,1,0

; Z
l_z:.word 1,1,1,1
.word 0,0,0,1
.word 0,0,1,0
.word 0,1,0,0
.word 1,1,1,1

.org 2000
frame_word_buffer:.word 0
; Here is where the frame word buffer data starts