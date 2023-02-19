;------------------------------------------------------------
.code
;------------------------------------------------------------
bits 16
org  1000h                        ; for bootsector
;------------------------------------------------------------

main:
     jmp start

;-----------------CONSTANTS-----------------
VIDMEM         equ 0B800h
WIN            equ 5
SCREENW		equ 80
SCREENH		equ 25
BGCOL          equ 6620h
SNAKECOL       equ 2020h
APPLECOL       equ 4020h
XARR           equ 2000h
YARR           equ 3000h
TIMER          equ 046Ch
UP			equ 0
DOWN		     equ 1
LEFT           equ 2
RIGHT          equ 3

;-----------------VARIABLES------------------
player_x:	     dw 40
player_y:	     dw 12
apple_x:       dw 16
apple_y:       dw 6
direction:     db 3
snake_len:     dw 1


;-------------------------------------------GAME SECTION------------------------------------------------
start:
     cli
     sti

     mov ax, 0003h
     int 10h                            ; call vios interrupt

     mov ax, VIDMEM                     ; setup videomem
     mov es, ax                         ; es:di video memory (0B800:0000 or B8000)

     ; first segment of "head"
     mov ax, [player_x]
     mov word [XARR], ax
     mov ax, [player_y]
     mov word [YARR], ax

;-------------------------------------------GAME LOGIC------------------------------------------------
game_loop:
     mov ax, BGCOL                      ; setup background color
     xor di, di
     mov cx, SCREENW*SCREENH            ; get full pixel val for rep
     rep stosw                          ; fill!

     ; draw snake
     xor bx, bx                         ; zero out bx (index for array)
     mov cx, [snake_len]
     mov ax, SNAKECOL
     .snake_draw_lp:
          imul di, [YARR+bx], SCREENW<<1
          imul dx, [XARR+bx], 2
          add di, dx
          stosw

          inc bx
          inc bx

     loop .snake_draw_lp


     ; draw apple
     imul di, [apple_y], SCREENW<<1
     imul dx, [apple_x], 2
     add di, dx
     mov ax, APPLECOL
     stosw

     ; set snake direction
     mov al, [direction]

     cmp al, UP
     je move_up
     cmp al, DOWN
     je move_down
     cmp al, LEFT
     je move_left
     cmp al, RIGHT
     je move_right

     jmp update_player                  ; for update snake state 


; inc or dec player position
move_up:
     dec word [player_y]
     jmp update_player

move_down:
     inc word [player_y]
     jmp update_player

move_left:
     dec word [player_x]
     jmp update_player

move_right:
     inc word [player_x]


update_player:
     ; update x, y position 
     imul bx, [snake_len], 2

     .update_lp:
          mov ax, [XARR-2+bx]           ; X Value 
          mov word [XARR+bx], ax
          mov ax, [YARR-2+bx]           ; Y Value
          mov word [YARR+bx], ax

          dec bx
          dec bx

     jnz .update_lp                     ; stop if first elem is head

     ; store updated data
     mov ax, [player_x]                 ; X Pos
     mov word [XARR], ax
     mov ax, [player_y]                 ; Y Pos
     mov word [YARR], ax

     ; lose condition
     ; -----------------BORDER OF THE SCREEN-----------------
     ;
     cmp word [player_y], -1            ; TOP
     je game_over
     cmp word [player_y], SCREENH       ; BOTTOM
     je game_over

     cmp word [player_x], -1            ; LEFT
     je game_over
     cmp word [player_x], SCREENW       ; RIGHT
     je game_over
     
     ; --------------------------HIT HIM SELF----------------------------
     ;
     cmp word [snake_len], 1            ; start segment
     je user_input

     mov bx, 2                          ; start at second elem (each is 2byte)
     mov cx, [snake_len]

check_lp:
     ; -------------------X---------------------
     mov ax, [player_x]
     cmp ax, [XARR+bx]
     jne .new_inc

     ; -------------------Y---------------------
     mov ax, [player_y]
     cmp ax, [YARR+bx] 
     je game_over

.new_inc:
     inc bx
     inc bx
loop check_lp

; get user iuput 
user_input:
     mov bl, [direction]                ; save current direction  

     ; for start game 
     mov ah, 1                     
     int 16h                            ; get key status
     jz if_collided

     xor ah, ah
     int 16h                            ; ah: scancode, al: ascii char 

     ; handle snake 
     cmp al, 'w'
     je w_pressed
     cmp al, 'a'
     je a_pressed
     cmp al, 's'
     je s_pressed
     cmp al, 'd'
     je d_pressed

     jmp if_collided

w_pressed:     
     mov bl, UP
     jmp if_collided
a_pressed:
     mov bl, LEFT
     jmp if_collided
s_pressed:
     mov bl, DOWN 
     jmp if_collided
d_pressed:
     mov bl, RIGHT


; is collide? 
if_collided:
     mov byte [direction], bl           ; update direction

     mov ax, [player_x]
     cmp ax, [apple_x]
     jne delay_lp

     mov ax, [player_y]
     cmp ax, [apple_y]
     jne delay_lp

     inc word [snake_len]               ; if collided with apple then increment snake length

     cmp word [snake_len], WIN          ; if snake len is 5
                                        ; then jmp to game_win                
     je game_win

     ; else 

; randomize apple position and respawn if not win
rand_pos_apple:
;--------------------X POS--------------------
     xor ah, ah                         ; read RTC
     int 1Ah                            ; real time clocks

     mov ax, dx                         
     xor dx, dx                         ; zero out upper half
     mov cx, SCREENW                    

     div cx                             ; (DX / AX) / CX
     mov word [apple_x], dx             ; move new value


;--------------------Y POS--------------------
     xor ah, ah                         ; read RTC
     int 1Ah                            ; real time clocks

     mov ax, dx                         
     xor dx, dx                         ; zero out upper half
     mov cx, SCREENH                    

     div cx                             ; (DX / AX) / CX
     mov word [apple_y], dx             ; move new value 


delay_lp:
     mov bx, [TIMER]
     inc bx
     inc bx
     .delay:   
          cmp [TIMER], bx
          jl .delay

jmp game_loop

;------------------------------GAME OVER------------------------------
game_win:
     mov dword [es:0000], 614f6157h     ; WO
     mov dword [es:0004], 6121614eh     ; N!

     cli                                ; disable interrupts  
     jmp retry                          ; retry if won

game_over:
     mov dword [es:0000], 64416447h     ; GA
     mov dword [es:0004], 6445644dh     ; ME
     mov dword [es:0012], 6456644fh     ; OV
     mov dword [es:0016], 64526445h     ; ER

     cli                                ; disable interrupts     
     hlt                                ; reboot if game over

retry:
     mov ax, 0
     int 16h
     jmp 0FFFFh:0