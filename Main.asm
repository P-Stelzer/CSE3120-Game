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
   startTime DWORD 0
GameData ENDS

getProfileField MACRO dest:REQ, field:REQ
   push edi
   mov edi, game.profile
   mov dest, (GameProfile PTR [edi]).field
   pop edi
   
ENDM


.const
; GRID_ROWS * GRID_COLS MUST BE EVEN AND NOT GREATER THAN 2*POOL_SIZE
MAX_GRID_ROWS EQU 9
MAX_GRID_COLS EQU 16
MAX_NUM_SYMBOLS EQU (MAX_GRID_ROWS * MAX_GRID_COLS) / 2

EASY_MODE GameProfile <0,4,7,14,28>
NORMAL_MODE GameProfile <1,6,9,27,54>
HARD_MODE GameProfile <2,9,16,72,144>

GAME_RESET GameData <>

GRID_ORIGIN_X EQU 3
GRID_ORIGIN_Y EQU 1

ROW_PADDING BYTE 2
COL_PADDING BYTE 4

POOL_SHUFFLES EQU 3
BOARD_SHUFFLES EQU 3

WELC_STR_1 BYTE "Welcome to Memory Matching!...",0
WELC_STR_2 BYTE "Select cards with the arrow keys...",0
WELC_STR_3 BYTE "Reveal the selected card with the space bar...",0
WELC_STR_4 BYTE "Each card has exactly one match...",0
WELC_STR_5 BYTE "If the last two revealed cards match, they remain visible...",0
WELC_STR_6 BYTE "Find all matches to win!...",0

DIFF_PROMPT BYTE "Choose Difficulty:",0

INFO_STR_1 BYTE "Attempted Matches: ",0
INFO_STR_2 BYTE "Matches Remaining: ",0

WIN_MESSAGE_1 BYTE "You matched all the cards in ",0
WIN_MESSAGE_2 BYTE " seconds!",0

PLAY_AGAIN_STR BYTE "Would you like to play again?",0



.data
game GameData <>

grid Card MAX_GRID_ROWS * MAX_GRID_COLS DUP(<33,-1>)

randSymbols BYTE MAX_NUM_SYMBOLS*2 DUP(0)

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
   mul COL_PADDING
   add al, GRID_ORIGIN_X
   mov dl, al

   mov dh, bl   ; set dh == y
   mov al, dh
   mul ROW_PADDING
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
   mul ROW_PADDING
   add al, 2
   add dh, al

   push edx

   call Gotoxy
   
   mov EDX, OFFSET INFO_STR_1

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
      mov EDX, OFFSET WIN_MESSAGE_1
      call WriteString

      INVOKE GetTickCount
      sub	eax,game.startTime

      ; Get and Write Minutes
	   mov edx, eax
	   ror edx, 16
	   and edx, 0000FFFFh
	   mov bx, 60000
      div bx
	   call	WriteDec

	   mov eax, ":"
	   call WriteChar

      ; Get and Write Seconds
	   mov eax, edx
	   ror edx, 16
	   and edx, 0000FFFFh
	   mov bx, 1000
      div bx
	   .IF eax < 10
	   	push eax
	   	mov eax, "0"
	   	call WriteChar
	   	pop eax
	   .ENDIF
	   call WriteDec

	   mov eax, "."
	   call WriteChar

      ; Write Millis
	   mov eax, edx
	   call WriteDec

      ;mov EDX, OFFSET WIN_MESSAGE_2
      ;call WriteString

   .ELSE
      push edx
      mov EDX, OFFSET INFO_STR_2
      call WriteString

      ; Clear decimal field so that digits are not left behind
      mov al, " "
      call WriteChar
      call WriteChar

      pop edx
      add dl, LENGTHOF INFO_STR_2
      dec dl
      call Gotoxy

      mov eax,0 
      getProfileField al, numSymbols
      sub al, game.numFound
      call WriteDec
   .ENDIF

   ret

DrawInfo ENDP



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

; === mShowWelc =====================================================================
mShowWelc MACRO text:REQ, x:REQ, y:REQ, delay:=<30>
   mPrintMessage x,y,delay,text
   ;mHideCursor
   call ReadChar
   .IF AX == 2960h
      jmp skip_intro
   .ENDIF
ENDM

   mShowWelc WELC_STR_1, GRID_ORIGIN_X, GRID_ORIGIN_Y
   mShowWelc WELC_STR_2, GRID_ORIGIN_X, %(GRID_ORIGIN_Y+3)
   mShowWelc WELC_STR_3, GRID_ORIGIN_X, %(GRID_ORIGIN_Y+5)
   mShowWelc WELC_STR_4, GRID_ORIGIN_X, %(GRID_ORIGIN_Y+8)
   mShowWelc WELC_STR_5, GRID_ORIGIN_X, %(GRID_ORIGIN_Y+10)
   mShowWelc WELC_STR_6, GRID_ORIGIN_X, %(GRID_ORIGIN_Y+13)
   jmp game_start

  skip_intro:
   mGotoXY GRID_ORIGIN_X, GRID_ORIGIN_Y
   mWriteString WELC_STR_1
   mGotoXY GRID_ORIGIN_X, %(GRID_ORIGIN_Y+3)
   mWriteString WELC_STR_2
   mGotoXY GRID_ORIGIN_X, %(GRID_ORIGIN_Y+5)
   mWriteString WELC_STR_3
   mGotoXY GRID_ORIGIN_X, %(GRID_ORIGIN_Y+8)
   mWriteString WELC_STR_4
   mGotoXY GRID_ORIGIN_X, %(GRID_ORIGIN_Y+10)
   mWriteString WELC_STR_5
   mGotoXY GRID_ORIGIN_X, %(GRID_ORIGIN_Y+13)
   mWriteString WELC_STR_6

  game_start:
   nop
   mPrintMessage GRID_ORIGIN_X, %(GRID_ORIGIN_Y+16),30,DIFF_PROMPT
   mChooseDifficulty %(GRID_ORIGIN_X+2), 18


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
   mFillCards grid, randSymbols, dl, dh

; GAME START

   call Clrscr


mLoadBoard MACRO
LOCAL loop_start, delay
.data
   delay DWORD ?
.code
   mov eax, white
   call SetTextColor

   getProfileField al, id

   .IF al == 0
      mov delay, 35
   .ELSEIF al == 1
      mov delay, 15
   .ELSEIF al == 2
      mov delay, 5
   .ELSE
      nop
   .ENDIF


   mov edi, 0

  loop_start:
   mov ax, di
   getProfileField bl, gridCols
   div bl
   mov dh, al
   mov dl, ah

   mov al, dl
   mul COL_PADDING
   add al, GRID_ORIGIN_X
   mov dl, al

   mov al, dh
   mul ROW_PADDING
   add al, GRID_ORIGIN_Y
   mov dh, al

   call gotoXY
   mov eax, "#"
   call WriteChar

   pushad
   INVOKE Sleep, delay	;; honk shoe
   popad

   inc edi
   mov eax, 0
   getProfileField ax, numCards
   cmp edi, eax
   jl loop_start
   
ENDM
   mLoadBoard



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
      ;   jmp game_done
      mHideCursor
      call ReadChar
      push eax
      
      mov eax, game.startTime
      .IF eax == 0
         INVOKE GetTickCount
         mov	game.startTime,eax   
      .ENDIF
      pop eax
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

  game_done:
   call DrawBoard

   call DrawInfo

mChoosePlayAgain MACRO x:REQ, y:REQ
LOCAL selected, yesLabel, noLabel, col, row
.data
   selected BYTE 0
   yesLabel BYTE "Yes",0
   noLabel BYTE "No",0
   col BYTE 0
   row BYTE 0
.code
   mov col, x
   mov row, y
   
   .WHILE 1

      .IF selected == 0
         mov eax, lightGreen
      .ELSE
         mov eax, white
      .ENDIF
      call SetTextColor
      mov bl, col
      mov bh, row
      mGotoXY bl, bh
      mWriteString yesLabel

      .IF selected == 1
         mov eax, lightGreen
      .ELSE
         mov eax, white
      .ENDIF
      call SetTextColor
      add ebx, LENGTHOF yesLabel
      add ebx, 2
      mov bh, row
      mGotoXY bl, bh
      mWriteString noLabel

      call ReadChar
      .IF AX == 4D00h && selected < 1; right
         inc selected
      .ELSEIF AX == 4B00h && selected > 0; left
         dec selected
      .ELSEIF AX == 3920h ; space
         .IF selected == 0
            call Clrscr
            ; RESET GAME DATA
            cld ; direction = forward
            mov ecx, SIZEOF GameData
            mov esi, OFFSET GAME_RESET ; source
            mov edi, OFFSET game ;target
            rep movsb
            mov eax, skip_intro
         .ELSEIF selected == 1
            mov eax, terminate
         .ELSE
            nop
         .ENDIF
         .BREAK
      .ELSE
         nop
      .ENDIF

   .ENDW

   push eax
   mov eax, white
   call SetTextColor
   pop eax
   jmp eax


ENDM

   mov dl, GRID_ORIGIN_X
   mov dh, GRID_ORIGIN_Y
   getProfileField al, gridRows
   mul ROW_PADDING
   add al, 6
   add dh, al
   add dl, 2 


   mPrintMessage GRID_ORIGIN_X, dh,30,PLAY_AGAIN_STR

   inc dh
   mChoosePlayAgain dl, dh


  terminate:
   exit
main ENDP

END main