; ; Formula fibonacci sequence: F(n) = F(n-1) + F(n-2)

;         LDI   r1, 0          ; F(n-2)
;         LDI   r2, 1          ; F(n-1)
;         LDI   r5, 0          ; F(n)

;         LDI   r3, 0          ; write address
;         LDI   r4, 1          ; increment amount

; loop:   ADD   r5, r1, r2     ; F(n) = F(n-2) + F(n-1)
;         STORE [r3], r5       ; mem[addr] = F0, save value to memory

;         MOV   r1, r2         ; F(n-2) = F(n-1)
;         MOV   r2, r5         ; F(n-1) = F(n)

;         ADD   r3, r3, r4     ; Increment address (r3 += 1)

;         LDI   r8, loop       ; Load address of loop
;         JMP   ALWAYS, r8     ; Jump back to loop

; .data
; .word 10, 20, 30, 40

.text
.word 0x1100
.word 0x1201
.word 0x1300
.word 0x1400
.word 0x8312
.word 0x5043
.word 0x3120
.word 0x3230
.word 0xD401
.word 0x1804
.word 0x6080
