INCLUDE Irvine32.inc
.data
cursorX BYTE 0
cursorY BYTE 0
.code

MoveRight PROC

 mov dl, cursorX
 inc dl
 inc dl

.IF dl >= 0 && dl <= 79
  mov al, " "
  call WriteChar

  mov dh, cursorY
  call Gotoxy

  mov al, 249
  call WriteChar
  call Gotoxy


  mov cursorX, dl
 .ENDIF

 ret

MoveRight ENDP


MoveLeft PROC

 mov dl, cursorX
 dec dl
 dec dl

.IF dl >= 0 && dl <= 79
  mov al, " "
  call WriteChar

  mov dh, cursorY
  call Gotoxy

  mov al, 249
  call WriteChar
  call Gotoxy


  mov cursorX, dl
 .ENDIF

 ret

MoveLeft ENDP



MoveUp PROC

 mov dh, cursorY
 dec dh

.IF dh >= 0 && dh <= 25
  mov al, " "
  call WriteChar

  mov dl, cursorX
  call Gotoxy

  mov al, 249
  call WriteChar
  call Gotoxy


  mov cursorY, dh
 .ENDIF

 ret

MoveUp ENDP


MoveDown PROC

 mov dh, cursorY
 inc dh

.IF dh >= 0 && dh <= 25
  mov al, " "
  call WriteChar

  mov dl, cursorX
  call Gotoxy

  mov al, 249
  call WriteChar
  call Gotoxy


  mov cursorY, dh
 .ENDIF

 ret

MoveDown ENDP


main PROC

mov al, 249
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