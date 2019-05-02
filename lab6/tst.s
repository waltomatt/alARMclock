test    EQU   0b10000000
teste   EQU   0b01000000

done    MOV   R0, #teste

        TST   R0, #test
        BNE   done
