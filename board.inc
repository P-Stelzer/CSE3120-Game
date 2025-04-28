
Card STRUCT
   symbol BYTE ?
   state BYTE 0 ; 0=hidden, 1=peek, 2=found, 3=wrong
Card ENDS

CARD_BACK_CHAR EQU 35

FillCards PROTO, 
   grid:PTR Card,
   symbols:PTR BYTE,
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
   push edx

   mov ebx, 0
 loop_start:
   mov eax, length
   call RandomRange

   ;; save first char in temp
   mov dl, string[ebx]
   push edx

   ;; place second char in first char
   mov dl, string[eax]
   mov string[ebx], dl

   ;; replace first char in second char
   pop edx
   mov string[eax], dl


   inc ebx
   cmp ebx, length
   jb loop_start

   pop edx
   pop eax
   pop ebx

ENDM


; === FillCards ==========================================================================
mFillCards MACRO grid:REQ, num_rows:REQ, num_cols:REQ
LOCAL loop_row, loop_column
   push ecx
   push edi
   push eax

; LOAD SYMBOLS INTO CARDS
   mov ecx, num_rows
   mov edi, 0

 loop_row:
   push ecx
   mov ecx, num_cols

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