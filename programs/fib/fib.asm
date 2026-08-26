; Formula fibonacci sequence: F(n) = F(n-1) + F(n-2)

        LDI   r1, 0          ; F(n-2)
        LDI   r2, 1          ; F(n-1)
        LDI   r5, 0          ; F(n)

        LDI   r3, 0          ; write address
        LDI   r4, 1          ; increment amount

loop:   ADD   r5, r1, r2     ; F(n) = F(n-2) + F(n-1)
        STORE [r3], r5       ; mem[addr] = F0, save value to memory

        MOV   r1, r2         ; F(n-2) = F(n-1)
        MOV   r2, r5         ; F(n-1) = F(n)

        ADD   r3, r3, r4     ; Increment address (r3 += 1)

        LDI   r8, loop       ; Load address of loop
        JMP   ALWAYS, r8     ; Jump back to loop
