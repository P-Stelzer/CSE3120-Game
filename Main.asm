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

; GRID_ROWS * GRID_COLS MUST BE EVEN
GRID_ROWS EQU 6
GRID_COLS EQU 8
GRID_ELEM_SIZE EQU TYPE Card
grid Card GRID_ROWS * GRID_COLS DUP(<33,0>)

NUM_SYMBOLS EQU (GRID_ROWS * GRID_COLS) / 2
randSymbols BYTE NUM_SYMBOLS*2 DUP(?)


peakOne DWORD 0



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
   ; call Clrscr

   mov ecx, GRID_ROWS
   mov ebx, 0 ; y
   mov edi, 0

 draw_row:
   push ecx
   mov ecx, GRID_COLS
   mov esi, 0 ; x

 draw_col:
   mov eax, esi
   mov ah, (Card PTR grid[0 + edi * TYPE grid]).state
   .IF al == cursorX && bl == cursorY
      mov eax, green
   .ELSEIF ah == 1
      mov eax, lightRed
   .ELSE
      mov eax, white
   .ENDIF
   call SetTextColor



   mov al, (Card PTR grid[0 + edi * TYPE grid]).state
   .IF al == 0
      mov al, CARD_BACK_CHAR
   .ELSE
      mov al, (Card PTR grid[0 + edi * TYPE grid]).symbol
   .ENDIF

   mov edx, esi ; set dl == x
   mov dh, bl   ; set dh == y
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

  mov al, (Card PTR grid).state

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
   ; mov al, (Card PTR grid).state
   ; lea eax, (Card PTR grid).state
   mov al, randSymbols[edi]
   mov (Card PTR grid[0 + edi * TYPE grid]).symbol, al
   ; mov al, (Card PTR grid[ebx + esi * TYPE grid]).symbol

   inc esi
   inc edi
   loop loop_col

   inc ebx
   pop ecx
   loop loop_row


; GAME LOOP
   mov ebx, TYPE WORD
   .WHILE 1
      call DrawBoard
      call ReadChar
      .IF AX == 4D00h ; right
         INVOKE MoveRight
      .ELSEIF AX == 4800h ; up
         INVOKE MoveUp
      .ELSEIF AX == 5000h ; down
         INVOKE MoveDown
      .ELSEIF AX == 4B00h ; left
         INVOKE MoveLeft
      .ELSEIF AX == 3920h ; space
         mov eax, 0
         mov al, cursorY
         mov bl, GRID_COLS
         mul bl
         add al, cursorX
         lea ebx, grid[0 + eax * TYPE grid]
         mov dl, (Card PTR [ebx]).state
         .IF dl == 0
            mov (Card PTR [ebx]).state, 1
         .ENDIF

      .ELSE
         mov AX, 0
      .ENDIF
   .ENDW
   
   exit
main ENDP




END main