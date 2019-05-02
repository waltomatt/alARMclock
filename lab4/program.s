INCLUDE     library.s

data        DEFB  'Bye! \0'
data2       DEFB  'World! \0'

            ALIGN       4

Main        ADR   R0, data
            BL    Write_str
            ADR   R0, data2
            BL    Write_str
done        B     done
