INCLUDE queue.inc
INCLUDE Irvine32.inc

.code
Enqueue PROC, q:Queue, e:DWORD
   mov edx,0
   mov dl, q.back

   mov eax, e
   mov DWORD PTR [q.arr + edx], eax
   inc q.back
   mov ax, 0
   mov al, q.back
   mov bl, 100
   div bl
   mov q.back, ah

   ret
Enqueue ENDP


Dequeue PROC, q:Queue
   mov edx,0
   mov dl, q.front

   mov eax, DWORD PTR [q.arr + edx]
   inc q.front
   push eax
   mov ax, 0
   mov al, q.front
   mov bl, 100
   div bl
   mov q.front, ah
   pop eax


   ret
Dequeue ENDP


END