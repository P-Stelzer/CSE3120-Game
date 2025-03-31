; Authors:
;    Peter Stelzer
;    Kyle Gibson


INCLUDE Irvine32.inc



.data
Card STRUCT
   symbol BYTE ?
   state BYTE 0 ; 0=hidden, 1=peek, 2=found, 3=wrong
Card ENDS

CARD_BACK_CHAR EQU 35
cardRowPadding BYTE 2
cardColPadding BYTE 4

cursorX BYTE 0
cursorY BYTE 0

; GRID_ROWS * GRID_COLS MUST BE EVEN AND NOT GREATER THAN 2*POOL_SIZE
GRID_ROWS EQU 5 ; suggested max 9
GRID_COLS EQU 8 ; suggested max 16

grid Card GRID_ROWS * GRID_COLS DUP(<33,0>)
gridOriginX BYTE 3
gridOriginY BYTE 1

NUM_SYMBOLS EQU (GRID_ROWS * GRID_COLS) / 2
randSymbols BYTE NUM_SYMBOLS*2 DUP(?)

POOL_SHUFFLES EQU 3
BOARD_SHUFFLES EQU 3


peek1 DWORD 0

numFound BYTE 0
numAttempts DWORD 0


welcomeMessage1 BYTE "Welcome to Memory Matching!...",0
welcomeMessage2 BYTE "Select cards with the arrow keys...",0
welcomeMessage3 BYTE "Reveal the selected card with space...",0
welcomeMessage4 BYTE "Each card has exactly one match...",0
welcomeMessage5 BYTE "If the last two revealed cards match, they remain visible...",0
welcomeMessage6 BYTE "Find all matches to win!...",0

infoStr1 BYTE "Attempted Matches: ",0
infoStr2 BYTE "Matches Remaining: ",0

winMessage BYTE "You matched all the cards!",0

; pool declaration must be fragmented like this else the rest of the memory tweaks
POOL_SIZE EQU 73
symbolPool BYTE "ABCDEFGHIJKLM"
           BYTE "NOPQRSTUVWXYZ"
           BYTE "abcdefghijklm"
           BYTE "nopqrstuvwxyz"
           BYTE "0123456789"
           BYTE "~!$%&+<=>?@"


.code

; === MoveRight =====================================================================
MoveRight MACRO

 mov dl, cursorX
 inc dl

 .IF dl >= 0 && dl < GRID_COLS
    mov cursorX, dl
 .ENDIF

ENDM

; === MoveLeft ======================================================================
MoveLeft MACRO

 mov dl, cursorX
 dec dl

 .IF dl >= 0 && dl < GRID_COLS
    mov cursorX, dl
 .ENDIF

ENDM


; === MoveUp ========================================================================
MoveUp MACRO

 mov dh, cursorY
 dec dh

 .IF dh >= 0 && dh < GRID_ROWS
    mov cursorY, dh
 .ENDIF

ENDM


; === MoveDown ======================================================================
MoveDown MACRO

 mov dh, cursorY
 inc dh

 .IF dh >= 0 && dh < GRID_ROWS
    mov cursorY, dh
 .ENDIF

ENDM


; === DrawBoard =====================================================================
DrawBoard PROC USES ecx ebx edi eax esi

   mov ecx, GRID_ROWS
   mov ebx, 0 ; y
   mov edi, 0

 draw_row:
   push ecx
   mov ecx, GRID_COLS
   mov esi, 0 ; x

 draw_col:
   ; Select Color
   mov eax, esi
   mov ah, (Card PTR grid[0 + edi * TYPE grid]).state
   .IF ah == 3 
      mov eax, red
   .ELSEIF ah == 1
      mov eax, cyan
   .ELSEIF al == cursorX && bl == cursorY
      .IF ah == 2
         mov eax, lightGray
      .ELSE
         mov eax, lightGreen
      .ENDIF
   .ELSEIF ah == 2
      mov eax, gray
   .ELSE
      mov eax, white
   .ENDIF
   call SetTextColor


   ; Select Glyph
   mov al, (Card PTR grid[0 + edi * TYPE grid]).state
   .IF al == 0
      mov al, CARD_BACK_CHAR
   .ELSEIF al == 3
      mov (Card PTR grid[0 + edi * TYPE grid]).state, 0
      mov al, (Card PTR grid[0 + edi * TYPE grid]).symbol
   .ELSE
      mov al, (Card PTR grid[0 + edi * TYPE grid]).symbol
   .ENDIF

   push eax


   ; Calculate Location
   mov edx, esi ; set dl == x
   mov al, dl
   mul cardColPadding
   add al, gridOriginX
   mov dl, al

   mov dh, bl   ; set dh == y
   mov al, dh
   mul cardRowPadding
   add al, gridOriginY
   mov dh, al

   pop eax
   call Gotoxy
   call WriteChar

   ; Loop Stuff
   inc esi
   inc edi
   dec ecx
   jnz draw_col

   inc ebx
   pop ecx
   dec ecx
   jnz draw_row

   ret
DrawBoard ENDP


; === DrawInfo ======================================================================
DrawInfo PROC USES eax edx

   mov eax, white
   call SetTextColor

   ; Number Attempts
   mov dl, gridOriginX
   mov dh, gridOriginY
   mov al, GRID_ROWS
   mul cardRowPadding
   add al, 2
   add dh, al

   push edx

   call Gotoxy
   
   mov EDX, OFFSET infoStr1

   call WriteString

   mov eax, numAttempts

   call WriteDec


   ; Pairs Remaining
   pop edx
   inc dh

   call Gotoxy
   
   .IF numFound >= NUM_SYMBOLS
      mov EDX, OFFSET winMessage
      call WriteString
   .ELSE
      push edx
      mov EDX, OFFSET infoStr2
      call WriteString

      ; Clear decimal field so that digits are not left behind
      mov al, " "
      call WriteChar
      call WriteChar

      pop edx
      add dl, LENGTHOF infoStr2
      dec dl
      call Gotoxy

      mov eax, NUM_SYMBOLS
      sub al, numFound
      call WriteDec
   .ENDIF

   ret

DrawInfo ENDP


; === mShowWelc =====================================================================
mShowWelc MACRO message
   call Gotoxy
   push edx
   mov edx, OFFSET message
   call WriteString
   pop edx
   mHideCursor
   call ReadChar
   call Clrscr
   .IF AX == 2960h
      jmp game_loop
   .ENDIF
ENDM


; === mPeekCard =====================================================================
mPeekCard MACRO
   ; GET CARD INDEX UNDER CURSOR
   mov eax, 0
   mov al, cursorY
   mov bl, GRID_COLS
   mul bl
   add al, cursorX
   
   ; LOAD CARD AND CHECK STATE
   lea ebx, grid[0 + eax * TYPE grid]
   mov dl, (Card PTR [ebx]).state
   .IF dl == 0
      mov (Card PTR [ebx]).state, 1
   
      .IF peek1 == 0
         mov peek1, ebx
      .ELSE
         inc numAttempts
         mov eax, peek1
         mov dh, (Card PTR [ebx]).symbol
         mov dl, (Card PTR [eax]).symbol
   
         .IF dh == dl
            mov (Card PTR [ebx]).state, 2
            mov (Card PTR [eax]).state, 2
            inc numFound
         .ELSE
            mov (Card PTR [ebx]).state, 3
            mov (Card PTR [eax]).state, 3
         .ENDIF
         mov peek1, 0
      .ENDIF
   
   
   .ENDIF
   
ENDM


; === mRevealBoard ==================================================================
mRevealBoard MACRO
   mov ecx, GRID_ROWS
   mov ebx, 0 ; y
   mov edi, 0
 
 loop_row_1:
   push ecx
   mov ecx, GRID_COLS
   mov esi, 0 ; x
 
 loop_col_1:
   mov al, (Card PTR grid[0 + edi * TYPE grid]).state
   .IF al == 0
      mov (Card PTR grid[0 + edi * TYPE grid]).state, 3
   .ENDIF
 
   inc esi
   inc edi
   loop loop_col_1
 
   inc ebx
   pop ecx
   loop loop_row_1

ENDM


; === mHideCursor ===================================================================
mHideCursor MACRO
   push edx
   push eax
   call GetMaxXY
   mov dh, al
   dec dh
   dec dl
   call GotoXY
   pop eax
   pop edx
ENDM


; === MAIN ==========================================================================
main PROC

call Randomize

; GENERATE RANDOM SYMBOLS IN PAIRS
   ; SHUFFLE Pool
   mov ecx, POOL_SHUFFLES
 pool_shuffle_loop:
   push ecx

   mov ecx, POOL_SIZE
   mov ebx, 0
 pool_shuffle_once:
   mov eax, POOL_SIZE
   call RandomRange
   mov dl, symbolPool[ebx]
   push edx
   mov dl, symbolPool[eax]
   mov symbolPool[ebx], dl
   pop edx
   mov symbolPool[eax], dl
   inc ebx
   loop pool_shuffle_once

   pop ecx
   loop pool_shuffle_loop

   ; FILL ARRAY
   mov ecx, NUM_SYMBOLS
   mov ebx, 0
   mov esi, 0

 board_init_loop:
   mov al, symbolPool[esi]
   mov randSymbols[ebx], al
   inc ebx
   mov randSymbols[ebx], al
   inc esi
   inc ebx
   loop board_init_loop

   ; SHUFFLE ARRAY
   mov ecx, BOARD_SHUFFLES
 board_shuffle_loop:
   push ecx

   mov ecx, NUM_SYMBOLS*2
   mov ebx, 0
 board_shuffle_once:
   mov eax, NUM_SYMBOLS*2
   call RandomRange
   mov dl, randSymbols[ebx]
   push edx
   mov dl, randSymbols[eax]
   mov randSymbols[ebx], dl
   pop edx
   mov randSymbols[eax], dl
   inc ebx
   loop board_shuffle_once

   pop ecx
   loop board_shuffle_loop

   ; LOAD SYMBOLS INTO CARDS
   mov ecx, GRID_ROWS
   mov ebx, 0 ; y
   mov edi, 0

 loop_row:
   push ecx
   mov ecx, GRID_COLS
   mov esi, 0 ; x

 loop_col:
   mov al, randSymbols[edi]
   mov (Card PTR grid[0 + edi * TYPE grid]).symbol, al

   inc esi
   inc edi
   loop loop_col

   inc ebx
   pop ecx
   loop loop_row

; GAME START

   mov dl, gridOriginX
   mov dh, gridOriginY

   mShowWelc welcomeMessage1
   mShowWelc welcomeMessage2
   mShowWelc welcomeMessage3
   mShowWelc welcomeMessage4
   mShowWelc welcomeMessage5
   mShowWelc welcomeMessage6



 game_loop:
; GAME LOOP
   mov ebx, TYPE WORD
   .WHILE numFound < NUM_SYMBOLS
      call DrawBoard
      call DrawInfo
      mHideCursor
      call ReadChar
      .IF AX == 4D00h ; right
         MoveRight
      .ELSEIF AX == 4800h ; up
         MoveUp
      .ELSEIF AX == 5000h ; down
         MoveDown
      .ELSEIF AX == 4B00h ; left
         MoveLeft
      .ELSEIF AX == 3920h ; space
         mPeekCard
      .ELSEIF AX == 2960h ; ~
         mRevealBoard
      .ELSE
         mov AX, 0
      .ENDIF
   .ENDW

   call DrawBoard

   call DrawInfo

   call ReadChar

   call Crlf


   exit
main ENDP

END main