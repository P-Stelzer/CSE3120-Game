


Queue Struct
   front BYTE 0
   back BYTE 0
   arr DWORD 100 DUP(?)
Queue ENDS


Enqueue PROTO,
   q:Queue,
   e:DWORD

Dequeue PROTO,
   q:QUEUE