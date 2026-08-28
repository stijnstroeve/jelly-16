


.text

.equ MAX_OFFSET, 4
.equ WORD_SIZE, 16
.equ FRAME_BUFFER_OFF, 128

        LDI r1, 0 ; Read offset
        LDI r2, 0 ; Value

loop:
        LOAD r3, [r1] ; Load data
        ADD r2, r2, r2 ; Shift bit to the left by 1
        ADD r2, r2, r3 ; Add value to r2
        ADDI r1, 1 ; Add 1 to address

        LDI r15, MAX_OFFSET
        CMP r1, r15 ; Compare offset to max offset
        LDI r15, loop
        JMP NEQ, r15

program_end:
        HALT



.data

; A
.word 0,1,1,0
.word 1,0,0,1
.word 1,0,0,1
.word 1,1,1,1
.word 1,0,0,1

; B
.word 1,1,1,0
.word 1,0,0,1
.word 1,1,1,0
.word 1,0,0,1
.word 1,1,1,0

; C
.word 1,1,1,1
.word 1,0,0,0
.word 1,0,0,0
.word 1,0,0,0
.word 1,1,1,1

; D
.word 1,1,1,0
.word 1,0,0,1
.word 1,0,0,1
.word 1,0,0,1
.word 1,1,1,0

; E
.word 1,1,1,1
.word 1,0,0,0
.word 1,1,1,1
.word 1,0,0,0
.word 1,1,1,1

; F
.word 1,1,1,1
.word 1,0,0,0
.word 1,1,1,0
.word 1,0,0,0
.word 1,0,0,0

; G
.word 0,1,1,1
.word 1,0,0,0
.word 1,0,1,1
.word 1,0,0,1
.word 0,1,1,1

; H
.word 1,0,0,1
.word 1,0,0,1
.word 1,1,1,1
.word 1,0,0,1
.word 1,0,0,1

; I
.word 1
.word 1
.word 1
.word 1
.word 1

; J
.word 0,0,0,1
.word 0,0,0,1
.word 0,0,0,1
.word 1,0,0,1
.word 0,1,1,0

; K
.word 1,0,0,1
.word 1,0,1,0
.word 1,1,0,0
.word 1,0,1,0
.word 1,0,0,1

; L
.word 1,0,0,0
.word 1,0,0,0
.word 1,0,0,0
.word 1,0,0,0
.word 1,1,1,1

; M
.word 1,0,0,1
.word 1,1,1,1
.word 1,0,0,1
.word 1,0,0,1
.word 1,0,0,1


; N
.word 1,0,0,1
.word 1,1,0,1
.word 1,0,1,1
.word 1,0,0,1
.word 1,0,0,1

; O
.word 0,1,1,0
.word 1,0,0,1
.word 1,0,0,1
.word 1,0,0,1
.word 0,1,1,0

; P
.word 0,1,1,0
.word 1,0,0,1
.word 1,1,1,0
.word 1,0,0,0
.word 0,0,0,0

; Q
.word 0,1,1,0
.word 1,0,0,1
.word 1,0,0,1
.word 1,0,1,1
.word 0,1,1,0

; R
.word 0,1,1,0
.word 1,0,0,1
.word 1,1,1,0
.word 1,0,1,0
.word 1,0,0,1

; S
.word 0,1,1,1
.word 1,0,0,0
.word 0,1,1,1
.word 0,0,0,1
.word 1,1,1,0

; T
.word 1,1,1
.word 0,1,0
.word 0,1,0
.word 0,1,0
.word 0,1,0

; U
.word 1,0,0,1
.word 1,0,0,1
.word 1,0,0,1
.word 1,0,0,1
.word 0,1,1,0

; V
.word 1,0,1
.word 1,0,1
.word 1,0,1
.word 1,0,1
.word 0,1,0

; W
.word 1,0,1,0,1
.word 1,0,1,0,1
.word 1,0,1,0,1
.word 1,0,1,0,1
.word 0,1,0,1,0

; X
.word 1,0,0,1
.word 0,1,1,0
.word 0,1,1,0
.word 1,0,0,1
.word 1,0,0,1

; Y
.word 1,0,1
.word 1,0,1
.word 0,1,0
.word 0,1,0
.word 0,1,0

; Z
.word 1,1,1,1
.word 0,0,0,1
.word 0,0,1,0
.word 0,1,0,0
.word 1,1,1,1

; Charachter widths
.word 4,4,4,4,4,4,4,4,1,4,4,4,4,4,4,4,4,4,4,3,4,3,5,4,3,4