

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


mPrintMessage MACRO x:REQ, y:REQ, delay:REQ, text:REQ
LOCAL string, printloop, printexit
	.data
	string BYTE text,0	;; add null terminator
	.code
	push	edx
	push eax

	mov	edx,OFFSET string
	mGotoXY x,y

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