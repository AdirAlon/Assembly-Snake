IDEAL
MODEL small
STACK 100h
DATASEG
; --------------------------
; Your variables here
; --------------------------
snakelength dw 2					;The current length of the snake (starts at 2)
appleLoc dw ?		            	;The apple location  (randomised later)
lastdirection db 'a'				;The last direction the snake moved (Starts at 'a' aka left)
loseflag db 0						;The flag  that indicates if the player lost (starts at 0 aka false)
dir dw -2							;Current facing direction (changed with input)
snakeLoc dw 1996, 1998, 2000		;snake start location is at pixel 2000 (the middle of the screen)
CODESEG
;--------------------------------------------------------------------------------------------------------------
; Game Function Procedures
;--------------------------------------------------------------------------------------------------------------
proc black_screen		;blackout the screen
push di
push ax
	mov di, 0			;create blank pixel
	mov al, ' '
	mov ah, 0
Bloop:
	mov [es:di], ax		;change every pixel blank
	add di, 2
	cmp di, 4000
jnz Bloop				;loops 2000 times (for every pixel)
pop ax
pop di
ret
endp black_screen
;--------------------------------------------------------------------------------------------------------------
;[bp + 4] - offset loseflag
;--------------------------------------------------------------------------------------------------------------
proc lose_screen			;F the screen
push bp
mov bp, sp
push di
push ax
mov di, [bp + 4]
mov [byte ptr di], 1
	mov di, 0			;create F pixel
	mov al, 'F'
	mov ah, 4
floop:
	mov [es:di], ax  	;F each pixel
	add di, 2
	cmp di, 4000
jnz floop				;loop 2000 times (for every pixel)
pop ax
pop di
pop bp
ret 2
endp lose_screen
;--------------------------------------------------------------------------------------------------------------
proc delay				;stops the code for a short period of time
push ax
push cx
	mov ax, 80			;runs double loop
	mov cx, 80
Dloop:

Dloop2:
	dec ax
jnz Dloop2
loop Dloop
pop cx
pop ax
ret
endp delay
;--------------------------------------------------------------------------------------------------------------
;[bp + 4] - offset appleLoc
;--------------------------------------------------------------------------------------------------------------
proc RandomPixel
push bp
mov bp, sp
push cx
push ax
push dx
push di
    regen:
 	mov cx, 2   ; :1: even number
    mov ah, 0
    int 1ah        ;pc clock
    mov ax, dx    ; :1: imput the clock (dx) into ax for math purposes
    mul cx         ;doubles the num for an even number 
    mov cx, 4000    
    div cx    ; :2: divide clock num by 4000 for module
	mov dl, 0
    mov di, dx
    mov ax, [es:di]
    cmp ah, 0
    jne regen
	mov di, [bp + 4]
	mov [di], dx	;updates appleLoc to the new location
pop di
pop dx
pop ax
pop cx
pop bp
ret 2
endp RandomPixel
;--------------------------------------------------------------------------------------------------------------
;[bp + 4] - offset appleLoc
;[bp + 6] - offset snakelength
;--------------------------------------------------------------------------------------------------------------
proc PutApple
push bp
mov bp, sp
push bx
push si
push di
push [bp + 4]
call RandomPixel	;runs RandomPixel to update appleLoc
mov bx, 04A0h			;create apple pixel
mov di, [bp + 4]
mov si, [di]	;moves apple location to si
mov [es:si], bx		;puts apple in the apple location
mov di, [bp + 6]
inc [word ptr di]
pop di
pop si
pop bx
pop bp
ret 4
endp PutApple
;--------------------------------------------------------------------------------------------------------------
;[bp + 4] - offset snakelength
;[bp + 6] - offset snakeLoc
;--------------------------------------------------------------------------------------------------------------
proc drawsnake
push bp
mov bp, sp
push cx
push bx
push di
push si
mov di, [bp + 4]		;moves into di offset snakelength
mov cx, [di]
mov di, [bp + 6]		;moves into di offset snakeLoc
mov bx, 0330h			;moves into bx the snake pixel (light blue '0')
drawLoop:	
mov si, [di]			
mov [es:si], bx
add di, 2
loop drawloop			;print bx at every pixel according to snakeLoc array
pop si
pop di
pop bx
pop cx
pop bp
ret 4
endp drawsnake
;--------------------------------------------------------------------------------------------------------------
;[bp + 4] - offset snakelength
;[bp + 6] - offset snakeLoc
;--------------------------------------------------------------------------------------------------------------
proc delSnake
push bp
mov bp, sp
push cx
push bx
push di
push si
mov di, [bp + 4]		;moves into di offset snakelength
mov cx, [di]
dec cx
shl cx, 1				;multiply cx by 2
add cx, [bp + 6]		;adds to cx offset snakeLoc to get to the last offset of snakeLoc
mov di, cx
mov bx, 0020h			;moves into bx the background pixel (Black space)
mov si, [di]
mov [es:si], bx			;delete the last pixel of the snake
pop si
pop di
pop bx
pop cx
pop bp
ret 4
endp delSnake
;--------------------------------------------------------------------------------------------------------------
;[bp + 4] - offset snakelength
;[bp + 6] - offset snakeLoc
;--------------------------------------------------------------------------------------------------------------
proc shiftsnake
push bp
mov bp, sp
push bx
push cx
push ax
push di
    mov di, [bp + 4]
	mov bx, [bp + 6]
	mov cx, [di]
	mov ax, [bx]
shiftloop:
	add bx, 2		;move bx up
	xor ax, [bx]
	xor [bx], ax		;xor swap ax bx
	xor ax, [bx]
loop shiftloop
pop di
pop ax
pop cx
pop bx
pop bp
ret 4
endp shiftsnake
;--------------------------------------------------------------------------------------------------------------
;[bp + 4] - offset appleLoc
;[bp + 6] - offset snakeLoc
;[bp + 8] - offset snakelength
;--------------------------------------------------------------------------------------------------------------
proc appleCheck
push bp
mov bp, sp
push ax
push bx
push di
push si
mov si, [bp + 4]			
mov ax, [si]						;moves into ax value of appleLoc
mov si, [bp + 6]			
mov bx, [si]						;moves into bx value of snakeLoc
cmp ax, bx							;compare apple location to snake head location
jnz notapple
mov si, [bp + 4]
mov [si], bx
push [bp + 8]
push [bp + 4]
call putapple						;if apple eaten call put apple to make a new one
notapple:
pop si
pop di
pop bx
pop ax
pop bp
ret 6
endp appleCheck
;--------------------------------------------------------------------------------------------------------------
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Movement Procedures 
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;[bp + 4] - offset snakeLoc
;[bp + 6] - offset loseflag
;[bp + 8] - offset snakelength
;[bp + 10] - how to change ax (-160, 160, 2, -2)
;[bp + 12] - what to compare for border
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
proc move 		
push bp
mov bp, sp
push di
push ax
push si
push bx
mov si, [bp + 4]
push [bp + 4]
push [bp + 8]
call delSnake           ;deletes previous snake
mov ax, [si]
add ax, [bp + 10]             ;calaculates the new snake head
mov di, ax
mov bx, [es:di]
cmp bl, 48
jne continue
mov bx, [bp + 6]
mov [byte ptr bx], 1
continue:
mov ax, di
push [bp + 4]
push [bp + 8]
call shiftsnake         ;shifts the snake array
mov [si], ax      ;update the snake array ro the new head
pop bx
pop si
pop ax
pop di
pop bp
ret 8
endp move
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
start:
	mov ax, @data
	mov ds, ax
; --------------------------
; Your code here
; --------------------------

	mov ax, 0b800h		;prepare extra segment 
	mov es, ax
call black_screen    	;blackout the screen
push offset snakelength
push offset appleLoc
call PutApple
push offset snakeLoc
push offset snakelength
call drawsnake
jmp input1
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
mup:
cmp [lastdirection], 's'
jz mdown
cmp [snakeLoc], 160
jae nodead
jmp exit
nodead:
mov [word ptr dir], -160                   ;for move
mov [lastdirection], 'w'
jmp input
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
mdown:
cmp [lastdirection], 'w'
jz mup
cmp [snakeLoc], 3839
jle noded
jmp exit
noded:
mov [word ptr dir], 160                    ;for move
mov [lastdirection], 's'
jmp input
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
mleft:
cmp [lastdirection], 'd'
jz mright
	mov ax, [snakeLoc]
	mov bl, 160
	div bl
	cmp ah, 0				;checks boreder
jne nded
    jmp exit
nded:
mov [word ptr dir], -2                     ;for move
mov [lastdirection], 'a'
jmp input
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
mright:
cmp [lastdirection], 'a'
jz mleft
	mov ax, [snakeLoc]		;moves di to ax for mathematical use
	add ax, 2
	mov bl, 160
	div bl
	cmp ah, 0				;checks boreder
jne nopded
    jmp exit
nopded:
mov [word ptr dir], 2                      ;for move
mov [lastdirection], 'd'
jmp input
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
input:
push [dir]
push offset snakelength
push offset loseflag
push offset snakeLoc
call move
push offset snakeLoc
push offset snakelength
call drawsnake
    cmp [byte ptr loseflag], 0
    jnz exit
    push offset snakeLength
    push offset snakeLoc
    push offset appleLoc
	call appleCheck
	call delay
mov ah,1
	int 16h					;check input
    mov al, [lastdirection]
	je afk
    input1:
	mov ah,0
	int 16h 				;change the input
	afk:
	cmp al,'w'				;moves according to input
	jne mupb
    jmp mup
    mupb:
	cmp al,'s'
	jne mdownb
    jmp mdown
    mdownb:
	cmp al,'a'
	jne mleftb
    jmp mleft
    mleftb:
	cmp al,'d'
	jne mrightb
    jmp mright
    mrightb:
	cmp al,'e'
	je exit
	jmp input

exit:
push offset loseflag
call lose_screen
call delay
mov ax, 4c00h
int 21h
END start
