;--------------------------------------------------------
bits 16                                                 ;
org 07C00h                                              ;
;--------------------------------------------------------

; macros 
%define ENDL 0x0D, 0x0A

jmp short start
nop

;------------------------------CONSTANTS------------------------------
KERNEL_LOAD_ADDR         equ 1000h
DRIVE                    equ 0
KERNEL_SECTOR            equ 2
KERNEL_SECTORS_LENGTH    equ 3


;-------------------------------LOGIC-----------------------------
start:
     ; setup segments
     xor ax, ax
     mov es, ax
     mov ds, ax

     ; setup stack
     mov ss, ax
     mov sp, 07C00h                ; stack start point

     mov si, msg_boot
     call puts

     mov cl, KERNEL_SECTOR         ; sector
	mov al, KERNEL_SECTORS_LENGTH ; number of sectors
	mov bx, KERNEL_LOAD_ADDR
     call load_sector

     mov si, msg_jmp_to_kernal
     call puts

     mov ax, 0
     mov es, ax
     mov bx, KERNEL_LOAD_ADDR
     jmp bx


err_wait_for_key:
     mov si, msg_fail
     call puts

     mov ah, 0 
     int 16h
     jmp 0FFFFh:0

load_sector:
     mov dl, DRIVE                 ; drive
     mov dh, 0                     ; head
     mov ch, 0                     ; cylinder
     mov ah, KERNEL_SECTOR
     int 13h                       ; read!
     jnc .done

     mov si, msg_err_load
     call puts

     jmp err_wait_for_key

.done:
     ret

; print char to screen
; params:
;    ds:si = points to string
puts:
     ; save registers will modified
     push si
     push ax
     push bx

.loop:
     lodsb                         ; loads next character in al
     or al, al                     ; verify if next character is null?
     jz .done

     mov ah, 0x0E                  ; call bios interrupt
     mov bh, 0                     ; set page number to 0
     int 10h

     jmp .loop                     ; while (al == NULL)

.done:
     pop bx
     pop ax
     pop si
     ret

.halt:
     cli 
     hlt


;----------------------------STRINGS--------------------------------
msg_boot:           db 'Loading...', ENDL, 0
msg_fail:           db 'Something is wrong. press any key', ENDL, 0
msg_err_load:       db 'Error loading kernel', ENDL, 0
msg_jmp_to_kernal:  db 'JUMP TO THE KERNAL!!', ENDL, '* if kernel is not loaded its mean something is wrong try reboot *', ENDL 0


;------------------------------SECTOR SET------------------------------
times 510-($-$$) db 0
dw 0AA55h                          ; boot sign

