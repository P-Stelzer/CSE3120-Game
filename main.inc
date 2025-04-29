INCLUDE Irvine32.inc

GameProfile STRUCT
   id BYTE 0
   gridRows BYTE 0
   gridCols BYTE 0
   numSymbols BYTE 0
   numCards WORD 0
   printDelay BYTE 0
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


Card STRUCT
   symbol BYTE ?
   state BYTE 0 ; 0=hidden, 1=peek, 2=found, 3=wrong
Card ENDS


; === getProfileField =====================================================================
getProfileField MACRO dest:REQ, field:REQ
   push edi
   mov edi, game.profile
   mov dest, (GameProfile PTR [edi]).field
   pop edi
   
ENDM


; === mLoadBoard =====================================================================
mLoadBoard MACRO
LOCAL loop_start, delay
.data
   delay DWORD ?
.code
   ; CREATE BOARD OF WHITE "#"s
   mov eax, white
   call SetTextColor

   mov eax, 0
   getProfileField al, printDelay
   mov delay, eax


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
   INVOKE Sleep, delay	; delay between chars appearing
   popad

   inc edi
   mov eax, 0
   getProfileField ax, numCards
   cmp edi, eax
   jl loop_start
   
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


; === mChooseDifficulty ==============================================================
mChooseDifficulty MACRO x:REQ, y:REQ
LOCAL selected
.data
   selected BYTE 0
   easyLabel BYTE "Easy",0
   normalLabel BYTE "Normal",0
   hardLabel BYTE "Hard",0
.code
   .WHILE 1
      ; color of highlighted text
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

      mHideCursor

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


; === mChoosePlayAgain ======================================================================
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
      ; color of highlighted text
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

      mHideCursor

      ; yes/no selected
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
   ; reset text color
   push eax
   mov eax, white
   call SetTextColor
   pop eax
   jmp eax

ENDM


; === Shuffle ==========================================================================
mShuffle MACRO string:REQ, length:REQ, numShuffles:REQ
LOCAL loop_start
   push ecx					

   mov ecx, 0					; initialize counter
 loop_start:
   mShuffleOnce string, length	; shuffle once

   inc ecx						
   cmp ecx, numShuffles			; check if done
   jb loop_start				; loop if # of shuffles not reached

   pop ecx

ENDM


; === ShuffleOnce ==========================================================================
mShuffleOnce MACRO string:REQ, length:REQ
LOCAL loop_start
   push ebx
   push eax

   mov ebx, 0
 loop_start:
   ; get random index
   mov eax, length
   call RandomRange

   ; swap current element with random index
   mSwap string, eax, ebx

   ; loop for elements
   inc ebx
   cmp ebx, length
   jb loop_start

   pop eax
   pop ebx

ENDM


; === mSwap ==========================================================================
mSwap MACRO string:REQ, loc1:REQ, loc2:REQ
   push edx
   ; save first char in temp
   mov dl, string[loc1]
   push edx

   ; place second char in first char
   mov dl, string[loc2]
   mov string[loc1], dl

   ; replace first char in second char
   pop edx
   mov string[loc2], dl
   pop edx
ENDM


; === FillCards ==========================================================================
mFillCards MACRO grid:REQ, randSymbols:REQ, num_rows:REQ, num_cols:REQ
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


; === mGotoXY ===================================================================
mGotoXY MACRO x:REQ, y:REQ
	push edx	

	mov dl, x
   mov dh, y
	call GotoXY

	pop edx
ENDM


; === mWriteString ===================================================================
mWriteString MACRO text:REQ
	push edx
	mov  edx,OFFSET text
	call WriteString
	pop  edx
ENDM


; === mPrintMessage ===================================================================
mPrintMessage MACRO x:REQ, y:REQ, delay:REQ, string:REQ
LOCAL string, printloop, printexit
	mGotoXY x,y

	push	edx
	push eax

	mov	edx,OFFSET string


	printloop:
	mov  al, [edx]		; get next char
	cmp al, 0			; check if at end
	jz printexit		; exit if at end
	call	WriteChar	; white the char into console

	push edx			; save progress to stack
	INVOKE Sleep, delay	; text delay
	pop edx				; restore position

	inc edx				; next char
	jmp printloop		; repeat

	printexit:
	pop eax
	pop	edx
ENDM


; === mShowWelc =====================================================================
mShowWelc MACRO text:REQ, x:REQ, y:REQ, delay:=<30>
   mPrintMessage x,y,delay,text
   mHideCursor
   call ReadChar
   .IF AX == 2960h
      jmp skip_intro
   .ENDIF
ENDM


; === mHideCursor ===================================================================
mHideCursor MACRO

   push edx
   push eax
   call GetMaxXY		; screen dimensions
   mov dh, al
   mov dh, 0
   dec dl
   call GotoXY
   pop eax
   pop edx
						; move to bottom off screen
ENDM

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