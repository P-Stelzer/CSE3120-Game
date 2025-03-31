INCLUDE Irvine32.inc



.data
Card STRUCT
   symbol BYTE ?
   state BYTE 0 ; 0=hidden, 1=peek, 2=found
Card ENDS

DOT_CHAR EQU 249
CARD_BACK_CHAR EQU 35

cursorX BYTE 0
cursorY BYTE 0

GRID_ROWS EQU 3
GRID_COLS EQU 4
GRID_ELEM_SIZE EQU TYPE Card
grid Card GRID_ROWS * GRID_COLS DUP(<,>)

NUM_SYMBOLS EQU (GRID_ROWS * GRID_COLS) / 2
randSymbols BYTE NUM_SYMBOLS*2 DUP(?)



.code

; === MoveRight =================
MoveRight PROC

 mov dl, cursorX
 inc dl

 .IF dl >= 0 && dl < GRID_COLS
    mov cursorX, dl
 .ENDIF

 ret

MoveRight ENDP

; === MoveLeft =================
MoveLeft PROC

 mov dl, cursorX
 dec dl

 .IF dl >= 0 && dl < GRID_COLS
    mov cursorX, dl
 .ENDIF

 ret

MoveLeft ENDP


; === MoveUp =================
MoveUp PROC

 mov dh, cursorY
 dec dh

 .IF dh >= 0 && dh < GRID_ROWS
    mov cursorY, dh
 .ENDIF

 ret

MoveUp ENDP


; === MoveDown =================
MoveDown PROC

 mov dh, cursorY
 inc dh

 .IF dh >= 0 && dh < GRID_ROWS
    mov cursorY, dh
 .ENDIF

 ret

MoveDown ENDP


; === DrawBoard ===============================
DrawBoard PROC USES ecx ebx edi eax esi
   call Clrscr

   mov ecx, GRID_ROWS
   mov ebx, 0 ; y
   mov edi, 0

 draw_row:
   push ecx
   mov ecx, GRID_COLS
   mov esi, 0 ; x

 draw_col:
   mov eax, esi
   .IF al == cursorX && bl == cursorY
      mov eax, green
   .ELSE
      mov eax, white
   .ENDIF
   call SetTextColor



   mov al, (Card PTR grid[ebx + esi * TYPE grid]).state
   .IF al == 0
      mov al, CARD_BACK_CHAR
   .ELSE
      mov al, (Card PTR grid[ebx + esi * TYPE grid]).symbol
   .ENDIF

   mov edx, esi
   mov dh, bl
   call Gotoxy
   call WriteChar

   inc esi
   inc edi
   loop draw_col

   inc ebx
   pop ecx
   loop draw_row

   ret
DrawBoard ENDP


; === MAIN ==========================================================
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

   ; LOAD ARRAY INTO CARDS
   mov ecx, GRID_ROWS
   mov ebx, 0 ; y
   mov edi, 0

 loop_row:
   push ecx
   mov ecx, GRID_COLS
   mov esi, 0 ; x

 loop_col:
   mov al, randSymbols[edi]
   mov (Card PTR grid[ebx + esi * TYPE grid]).symbol, al

   inc esi
   inc edi
   loop loop_col

   inc ebx
   pop ecx
   loop loop_row


call DrawBoard


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
  call DrawBoard
 .ENDW

 exit
main ENDP




END main