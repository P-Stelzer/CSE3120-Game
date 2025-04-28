
INCLUDE Irvine32.inc
INCLUDE board.inc


.code
; === FillCards ==========================================================================
FillCards PROC, grid:PTR Card, symbols:PTR BYTE, num_rows:BYTE, num_cols:BYTE
   pushad

; LOAD SYMBOLS INTO CARDS
   mov ecx, 0
   mov cl, num_rows
   mov edi, 0

 loop_row:
   push ecx
   mov cl, num_cols

 loop_col:
   mov al, BYTE PTR symbols[edi]
   mov (Card PTR grid[0 + edi * TYPE grid]).symbol, al
   mov (Card PTR grid[0 + edi * TYPE grid]).state, 0

   inc edi
   loop loop_col

   pop ecx
   loop loop_row

   popad
   ret

FillCards ENDP

END