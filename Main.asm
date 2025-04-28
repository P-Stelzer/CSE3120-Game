; Authors:
;    Peter Stelzer
;    Kyle Gibson


INCLUDE Irvine32.inc
INCLUDE board.inc
INCLUDE draw.inc



GameProfile STRUCT
   id BYTE 0
   gridRows BYTE 0
   gridCols BYTE 0
   numSymbols BYTE 0
   numCards WORD 0
GameProfile ENDS


GameData STRUCT
   profile DWORD 0FFFFFFFFh ; offset of one of the profiles
   cursorX BYTE 0
   cursorY BYTE 0
   currentPeek DWORD 0
   numFound BYTE 0
   numAttempts DWORD 0
   startTime DWORD ?
GameData ENDS

getProfileField MACRO dest:REQ, field:REQ
   push edi
   mov edi, game.profile
   mov dest, (GameProfile PTR [edi]).field
   pop edi
   
ENDM

.const
EASY_MODE GameProfile <0,5,8,20,40>
NORMAL_MODE GameProfile <1,7,10,35,70>
HARD_MODE GameProfile <2,9,16,72,144>


.data

game GameData <>

cardRowPadding BYTE 2
cardColPadding BYTE 4


; GRID_ROWS * GRID_COLS MUST BE EVEN AND NOT GREATER THAN 2*POOL_SIZE
MAX_GRID_ROWS EQU 9
MAX_GRID_COLS EQU 16
MAX_NUM_SYMBOLS EQU (MAX_GRID_ROWS * MAX_GRID_COLS) / 2


grid Card MAX_GRID_ROWS * MAX_GRID_COLS DUP(<33,-1>)
GRID_ORIGIN_X EQU 3
GRID_ORIGIN_Y EQU 1


randSymbols BYTE MAX_NUM_SYMBOLS*2 DUP(0)

POOL_SHUFFLES EQU 3
BOARD_SHUFFLES EQU 3


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
; === DrawBoard =====================================================================
DrawBoard PROC USES ecx ebx edi eax esi

   getProfileField cl, gridRows
   mov ebx, 0 ; y
   mov edi, 0

 draw_row:
   push ecx
   getProfileField cl, gridCols
   mov esi, 0 ; x

 draw_col:
   ; Select Color
   mov eax, esi
   mov ah, (Card PTR grid[0 + edi * TYPE grid]).state
   .IF ah == 3 
      mov eax, red
   .ELSEIF ah == 1
      mov eax, cyan
   .ELSEIF al == game.cursorX && bl == game.cursorY
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
   add al, GRID_ORIGIN_X
   mov dl, al

   mov dh, bl   ; set dh == y
   mov al, dh
   mul cardRowPadding
   add al, GRID_ORIGIN_Y
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
   mov dl, GRID_ORIGIN_X
   mov dh, GRID_ORIGIN_Y
   getProfileField al, gridRows
   mul cardRowPadding
   add al, 2
   add dh, al

   push edx

   call Gotoxy
   
   mov EDX, OFFSET infoStr1

   call WriteString

   mov eax, game.numAttempts

   call WriteDec


   ; Pairs Remaining
   pop edx
   inc dh

   call Gotoxy
   
   getProfileField al, numSymbols
   mov ah, game.numFound
   .IF ah >= al
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

      mov eax,0 
      getProfileField al, numSymbols
      sub al, game.numFound
      call WriteDec
   .ENDIF

   ret

DrawInfo ENDP


; === mShowWelc =====================================================================
mShowWelc MACRO text:REQ, x:REQ, y:REQ, delay:=<30>
   mPrintMessage x,y,delay,text
   ;mHideCursor
   call ReadChar
   .IF AX == 2960h
      jmp game_start
   .ENDIF
ENDM


; === mPeekCard =====================================================================
mPeekCard MACRO
   ; GET CARD INDEX UNDER CURSOR
   mov eax, 0
   mov al, game.cursorY
   getProfileField bl, gridCols
   mul bl
   add al, game.cursorX
   
   ; LOAD CARD AND CHECK STATE
   lea ebx, grid[0 + eax * TYPE grid]
   mov dl, (Card PTR [ebx]).state
   .IF dl == 0
      mov (Card PTR [ebx]).state, 1
   
      mov edx, game.currentPeek
      .IF edx == 0
         mov game.currentPeek, ebx
      .ELSE
         inc game.numAttempts
         mov eax, game.currentPeek
         mov dh, (Card PTR [ebx]).symbol
         mov dl, (Card PTR [eax]).symbol
   
         .IF dh == dl
            mov (Card PTR [ebx]).state, 2
            mov (Card PTR [eax]).state, 2
            inc game.numFound
         .ELSE
            mov (Card PTR [ebx]).state, 3
            mov (Card PTR [eax]).state, 3
         .ENDIF
         mov game.currentPeek, 0
      .ENDIF
   
   
   .ENDIF
   
ENDM


; === mRevealBoard ==================================================================
mRevealBoard MACRO
LOCAL loop_start
   mov ecx, 0
   getProfileField cx, numCards
   mov edi, 0
 
 loop_start:
   mov al, (Card PTR grid[0 + edi * TYPE grid]).state
   .IF al == 0
      mov (Card PTR grid[0 + edi * TYPE grid]).state, 3
   .ENDIF
 
   inc edi
   loop loop_start

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


mChooseDifficulty MACRO x:REQ, y:REQ
LOCAL selected
.data
   selected BYTE 0
   easyLabel BYTE "Easy",0
   normalLabel BYTE "Normal",0
   hardLabel BYTE "Hard",0
.code
   .WHILE 1

      .IF selected == 0
         mov eax, lightGreen
      .ELSE
         mov eax, white
      .ENDIF
      call SetTextColor
      mov ebx, x
      mGotoXY bl, y
      mWriteString easyLabel

      .IF selected == 1
         mov eax, lightGreen
      .ELSE
         mov eax, white
      .ENDIF
      call SetTextColor
      add ebx, LENGTHOF easyLabel
      add ebx, 2
      mGotoXY bl, y
      mWriteString normalLabel

      .IF selected == 2
         mov eax, lightGreen
      .ELSE
         mov eax, white
      .ENDIF
      call SetTextColor
      add ebx, LENGTHOF normalLabel
      add ebx, 2
      mGotoXY bl, y
      mWriteString hardLabel

      call ReadChar
      .IF AX == 4D00h && selected < 2; right
         inc selected
      .ELSEIF AX == 4B00h && selected > 0; left
         dec selected
      .ELSEIF AX == 3920h ; space
         .IF selected == 0
            mov eax, OFFSET EASY_MODE 
         .ELSEIF selected == 1
            mov eax, OFFSET NORMAL_MODE 
         .ELSEIF selected == 2
            mov eax, OFFSET HARD_MODE 
         .ELSE
            nop
         .ENDIF

         mov game.profile, eax
         .BREAK
      .ELSE
         nop
      .ENDIF

   .ENDW


ENDM

; === MAIN ==========================================================================
main PROC

   mShowWelc <"Welcome to Memory Matching!...">, GRID_ORIGIN_X, GRID_ORIGIN_Y
   mShowWelc <"Select cards with the arrow keys...">, GRID_ORIGIN_X, %(GRID_ORIGIN_Y+3)
   mShowWelc <"Reveal the selected card with the space bar...">, GRID_ORIGIN_X, %(GRID_ORIGIN_Y+5)
   mShowWelc <"Each card has exactly one match...">, GRID_ORIGIN_X, %(GRID_ORIGIN_Y+8)
   mShowWelc <"If the last two revealed cards match, they remain visible...">, GRID_ORIGIN_X, %(GRID_ORIGIN_Y+10)
   mShowWelc < "Find all matches to win!...">, GRID_ORIGIN_X, %(GRID_ORIGIN_Y+13)

game_start:
nop
   mChooseDifficulty %(GRID_ORIGIN_X+2), 16


   call Randomize

; GENERATE RANDOM SYMBOLS IN PAIRS
   mShuffle symbolPool, POOL_SIZE, POOL_SHUFFLES

   ; Copy symbols into first half of the array
   cld ; direction = forward
   mov ecx, 0
   getProfileField cl, numSymbols
   mov esi, OFFSET symbolPool ; source
   mov edi, OFFSET randSymbols ;target
   rep movsb

   ; Repeat for second half
   getProfileField cl, numSymbols
   mov esi, OFFSET symbolPool
   rep movsb

   mov esi, 0
   getProfileField si, numCards
   mShuffle randSymbols, esi, BOARD_SHUFFLES


   getProfileField dl, gridRows
   getProfileField dh, gridCols
   mFillCards grid, dl, dh

; GAME START

   


   call Clrscr

; === MoveRight =====================================================================
MoveRight MACRO

 mov dl, game.cursorX
 inc dl

 getProfileField al, gridCols
 .IF dl >= 0 && dl < al
    mov game.cursorX, dl
 .ENDIF

ENDM

; === MoveLeft ======================================================================
MoveLeft MACRO

 mov dl, game.cursorX
 dec dl

 getProfileField al, gridCols
 .IF dl >= 0 && dl < al
    mov game.cursorX, dl
 .ENDIF

ENDM


; === MoveUp ========================================================================
MoveUp MACRO

 mov dh, game.cursorY
 dec dh

 getProfileField al, gridRows
 .IF dh >= 0 && dh < al
    mov game.cursorY, dh
 .ENDIF

ENDM


; === MoveDown ======================================================================
MoveDown MACRO

 mov dh, game.cursorY
 inc dh

 getProfileField al, gridRows
 .IF dh >= 0 && dh < al
    mov game.cursorY, dh
 .ENDIF

ENDM


 game_loop:
; GAME LOOP
   mov ebx, TYPE WORD

   .WHILE 1 ;game.numFound < (GameProfile PTR game.profile).numSymbols
      getProfileField al, numSymbols
      
      .IF al <= game.numFound
         .BREAK
      .ENDIF

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
      nop
         mPeekCard
      .ELSEIF AX == 2960h ; ~
         mRevealBoard
      .ELSE
         nop
      .ENDIF
   .ENDW

   call DrawBoard

   call DrawInfo

   call ReadChar

   call Crlf


   exit
main ENDP

END main