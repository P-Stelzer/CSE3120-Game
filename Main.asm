INCLUDE Irvine32.inc



.data
Card STRUCT
   symbol BYTE ?
   state BYTE 0 ; 0=hidden, 1=peek, 2=found
Card ENDS

DOT_CHAR EQU 249

cursorX BYTE 0
cursorY BYTE 0

GRID_ROWS EQU 3
GRID_COLS EQU 4
GRID_ELEM_SIZE EQU TYPE Card
grid Card GRID_ROWS * GRID_COLS DUP(<,>)

NUM_SYMBOLS EQU (GRID_ROWS * GRID_COLS) / 2
randSymbols BYTE NUM_SYMBOLS*2 DUP(?)



.code

MoveRight PROC

 mov dl, cursorX
 inc dl

.IF dl >= 0 && dl <= GRID_COLS
  mov al, " "
  call WriteChar

  mov dh, cursorY
  call Gotoxy

  mov al, DOT_CHAR
  call WriteChar
  call Gotoxy


  mov cursorX, dl
 .ENDIF

 ret

MoveRight ENDP


MoveLeft PROC

 mov dl, cursorX
 dec dl

.IF dl >= 0 && dl <= GRID_COLS
  mov al, " "
  call WriteChar

  mov dh, cursorY
  call Gotoxy

  mov al, DOT_CHAR
  call WriteChar
  call Gotoxy


  mov cursorX, dl
 .ENDIF

 ret

MoveLeft ENDP



MoveUp PROC

 mov dh, cursorY
 dec dh

.IF dh >= 0 && dh <= GRID_ROWS
  mov al, " "
  call WriteChar

  mov dl, cursorX
  call Gotoxy

  mov al, DOT_CHAR
  call WriteChar
  call Gotoxy


  mov cursorY, dh
 .ENDIF

 ret

MoveUp ENDP


MoveDown PROC

 mov dh, cursorY
 inc dh

.IF dh >= 0 && dh <= GRID_ROWS
  mov al, " "
  call WriteChar

  mov dl, cursorX
  call Gotoxy

  mov al, DOT_CHAR
  call WriteChar
  call Gotoxy


  mov cursorY, dh
 .ENDIF

 ret

MoveDown ENDP


main PROC

; GENERATE RANDOM SYMBOLS IN PAIRS
   ; FILL ARRAY
   mov ecx, NUM_SYMBOLS
   mov ebx, 0
   mov al, 97

 char_init_loop:
   mov randSymbols[ebx], al
   inc ebx
   mov randSymbols[ebx], al
   inc al
   inc ebx
   loop char_init_loop

   ; SHUFFLE ARRAY
   mov ecx, NUM_SYMBOLS*2
   mov ebx, 0
 char_rand_loop:
   mov eax, NUM_SYMBOLS*2
   call RandomRange
   mov dl, randSymbols[ebx]
   push edx
   mov dl, randSymbols[eax]
   mov randSymbols[ebx], dl
   pop edx
   mov randSymbols[eax], dl
   inc ebx
   loop char_rand_loop



;POPULATE GRID WITH RANDOM SYMBOLS
   mov ecx, GRID_ROWS
   mov ebx, 0 ; y
   mov ebp, 0

 row_loop:
   push ecx
   mov ecx, GRID_COLS
   mov esi, 0 ; x

 col_loop:
   mov al, randSymbols[ebp]
   inc ebp
   mov (Card PTR grid[ebx + esi * TYPE grid]).symbol, al


   mov edx, esi
   mov dh, bl
   call Gotoxy
   call WriteChar

   inc esi
   loop col_loop

   inc ebx
   pop ecx
   loop row_loop



mov al, DOT_CHAR
call WriteChar

mov dl, cursorX
mov dh, cursorY
call Gotoxy


mov ebx, TYPE WORD
 .WHILE 1
  call ReadChar
  .IF AX == 4D00h ; right
   INVOKE MoveRight
  .ELSEIF AX == 4800h ; up
   INVOKE MoveUp
  .ELSEIF AX == 5000h ; down
   INVOKE MoveDown
  .ELSEIF AX == 4B00h ; left
   INVOKE MoveLeft
  .ENDIF
 .ENDW

 exit
main ENDP




END main