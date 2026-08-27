; Formula fibonacci sequence: F(n) = F(n-1) + F(n-2)

        LDI   r1, 0          ; F(n-2)
        LDI   r2, 1          ; F(n-1)
        LDI   r3, 0          ; F(n)

        LDI   r4, 0          ; write address

loop:   ADD   r3, r1, r2     ; F(n) = F(n-2) + F(n-1)
        STORE [r4], r3       ; mem[addr] = F0, save value to memory

        MOV   r1, r2         ; F(n-2) = F(n-1)
        MOV   r2, r3         ; F(n-1) = F(n)

        ADDI  r4, 1          ; Increment address (r4 += 1)

        LDI   r8, loop       ; Load address of loop
        JMP   ALWAYS, r8     ; Jump back to loop
