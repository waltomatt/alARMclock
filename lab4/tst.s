MOV R0, #&71
TST R0, #&80
BEQ success
AND R0, R0, #&80
SUBS R0, R0, #&80
BEQ success
ADD R0, R0, R0
ADD R0, R0, R0
success MOV R1, #1
