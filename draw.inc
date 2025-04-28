

mGotoXY MACRO x:REQ, y:REQ
	push edx	

	mov dl, x
   mov dh, y
	call GotoXY

	pop edx
ENDM

mWriteString MACRO text:REQ
	push edx
	mov  edx,OFFSET text
	call WriteString
	pop  edx
ENDM


mPrintMessage MACRO x:REQ, y:REQ, delay:REQ, string:REQ
LOCAL string, printloop, printexit
	mGotoXY x,y

	push	edx
	push eax

	mov	edx,OFFSET string


	printloop:
	mov  al, [edx]		;; get next char
	cmp al, 0			;; check if at end
	jz printexit
	call	WriteChar

	push edx			;; save progress to stack
	INVOKE Sleep, delay	;; honk shoe
	pop edx			;; restore position

	inc edx
	jmp printloop

	printexit:
	pop eax
	pop	edx
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


