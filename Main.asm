INCLUDE Irvine32.inc



.data
Card STRUCT
   symbol BYTE ?
   state BYTE ? ; 0=hidden, 1=peek, 2=found
Card ENDS

DOT_CHAR EQU 249

cursorX BYTE 0
cursorY BYTE 0

GRID_ROWS EQU 3
GRID_COLS EQU 4
GRID_ELEM_SIZE EQU TYPE Card
grid DW GRID_ROWS * GRID_COLS DUP(?)




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

   mov ecx, GRID_ROWS
   mov ebx, 0 ; y

 row_loop:
   push ecx
   mov ecx, GRID_COLS
   mov esi, 0 ; x

 col_loop:
   mov eax, 26
   call RandomRange
   add al, 97
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