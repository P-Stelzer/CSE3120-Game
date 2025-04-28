
Card STRUCT
   symbol BYTE ?
   state BYTE 0 ; 0=hidden, 1=peek, 2=found, 3=wrong
Card ENDS

CARD_BACK_CHAR EQU 35

EXTERNDEF grid:Card, randSymbols:BYTE

FillCards PROTO, 
   grid:Card,
   symbols:BYTE,
   num_rows:BYTE,
   num_cols:BYTE


; === Shuffle ==========================================================================
mShuffle MACRO string:REQ, length:REQ, numShuffles:REQ
LOCAL loop_start
   push ecx

   mov ecx, 0
 loop_start:
   mShuffleOnce string, length

   inc ecx
   cmp ecx, numShuffles
   jb loop_start

   pop ecx

ENDM


; === ShuffleOnce ==========================================================================
mShuffleOnce MACRO string:REQ, length:REQ
LOCAL loop_start
   push ebx
   push eax

   mov ebx, 0
 loop_start:
   mov eax, length
   call RandomRange

   mSwap string, eax, ebx

   inc ebx
   cmp ebx, length
   jb loop_start

   pop eax
   pop ebx

ENDM


mSwap MACRO string:REQ, loc1:REQ, loc2:REQ
   push edx
   ;; save first char in temp
   mov dl, string[loc1]
   push edx

   ;; place second char in first char
   mov dl, string[loc2]
   mov string[loc1], dl

   ;; replace first char in second char
   pop edx
   mov string[loc2], dl
   pop edx
ENDM


; === FillCards ==========================================================================
mFillCards MACRO grid:REQ, num_rows:REQ, num_cols:REQ
LOCAL loop_row, loop_column
   push ecx
   push edi
   push eax

; LOAD SYMBOLS INTO CARDS
   mov ecx, 0
   mov cl, num_rows
   mov edi, 0

 loop_row:
   push ecx
   mov ecx, 0
   mov cl, num_cols

 loop_col:
   mov al, randSymbols[edi]
   mov (Card PTR grid[0 + edi * TYPE grid]).symbol, al
   mov (Card PTR grid[0 + edi * TYPE grid]).state, 0

   inc edi
   loop loop_col

   pop ecx
   loop loop_row

   pop eax
   pop edi
   pop ecx

ENDM