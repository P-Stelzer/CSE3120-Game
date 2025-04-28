
INCLUDE Irvine32.inc
INCLUDE board.inc


.code
; === FillCards ==========================================================================
FillCards PROC, gridp:Card, symbols:BYTE, num_rows:BYTE, num_cols:BYTE
   pushad

; LOAD SYMBOLS INTO CARDS
   mov ecx, 0
   mov cl, num_rows
   mov edi, 0

 loop_row:
   push ecx
   mov ecx, 0
   mov cl, num_cols

 loop_col:
   mov al, BYTE PTR symbols[edi]
   mov (Card PTR [gridp + edi * TYPE gridp]).symbol, al
   mov (Card PTR [gridp + edi * TYPE gridp]).state, 0

   inc edi
   loop loop_col

   pop ecx
   loop loop_row

   popad
   ret

FillCards ENDP

END