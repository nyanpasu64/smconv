.ifndef PRINT_LETTER_INC
PRINT_LETTER_INC=1

.global ClearTextScreen, PrintLetter, SetupPrintLetter
;-----------------------;-------------------------------------------------;
PL_CR = 0ah		; Carriage return
PL_RESET_TEXT = 01h	; Clear screen, reset text pointer
PL_SPACE = 20h		; Space - usually 20h
PL_STOP_TEXT = 00h	; Clear screen, do not reset text pointer
;-----------------------;-------------------------------------------------;

.endif
