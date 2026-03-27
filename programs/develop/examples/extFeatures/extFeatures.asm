;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                  ;
; EXT4 FEATURES READER EXAMPLE APPLICATION         ;  Inspired from example.asm
;                                                  ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This program will read the features bytes from an ext4 image
; Usage 
; ./extFeatures  fullPathOfImage
; 


format binary as ""                     ; Binary file format without extension

use32                                   ; Tell compiler to use 32 bit instructions
 
org 0                                   ; the base address of code, always 0x0

; The header

db 'MENUET01'
dd 1
dd START
dd I_END
dd MEM
dd STACKTOP
dd 0
dd 0

; The code area
 
include 'macros.inc'

; ext4 offsets
;   superblock -------- offset 1024
;   features -------- offset 0x5C
;   compat_feature_mask -------- offset 0x5C
;   incompat_feature_mask -------- offset 0x60
;   ro_compat_feature_mask -------- offset 0x64

super_block_offset = 1024
features_offset = 0x5C
num_of_bytes_in_feature_mask = 12; 3*4
label_offset = 0x78


xsize = 800
ysize = 800

include './helper.inc'


 
START:                 
        ; Read the features from the ext4 image
        mov     eax, 70                 ; Function 70: File system operations
        mov     ebx, file_read          ; Pointer to the file_read struct
        mcall

        ; skip label reading if error and store return code to display error message
        mov [rd_err], eax
        cmp [rd_err], 0
        jnz skip_label
        

        ; read label
        mov     eax, super_block_offset + label_offset
        mov     [file_read.Offset], eax

        mov     dword [file_read.size], 16

        lea     eax, [extlabel]
        mov     [file_read.return], eax

        mov     eax, 70
        mov     ebx, file_read         
        mcall

skip_label:
        ;Draw the window and display values
        call    draw_window             ; draw the window






 
; After the window is drawn, it's practical to have the main loop.
; Events are distributed from here.
 
event_wait:
        mov     eax, 10                 ; function 10 : wait until event
        mcall                           ; event type is returned in eax
 
        cmp     eax, 1                  ; Event redraw request ?
        je      red                     ; Expl.: there has been activity on screen and
                                        ; parts of the applications has to be redrawn.
 
        cmp     eax, 2                  ; Event key in buffer ?
        je      key                     ; Expl.: User has pressed a key while the
                                        ; app is at the top of the window stack.
 
        cmp     eax, 3                  ; Event button in buffer ?
        je      button                  ; Expl.: User has pressed one of the
                                        ; applications buttons.
 
        jmp     event_wait
 
;  The next section reads the event and processes data.
 
red:                                    ; Redraw event handler
        call    draw_window             ; We call the window_draw function and
        jmp     event_wait              ; jump back to event_wait
 
key:                                    ; Keypress event handler
        mov     eax, 2                  ; The key is returned in ah. The key must be
        mcall                           ; read and cleared from the system queue.
        jmp     event_wait              ; Just read the key, ignore it and jump to event_wait.
 
button:                                 ; Buttonpress event handler
        mov     eax,17                  ; The button number defined in window_draw
        mcall                           ; is returned to ah.
 
        cmp     ah,1                    ; button id=1 ?
        jne     noclose
        mov     eax,-1                  ; Function -1 : close this program
        mcall
 
noclose:
        jmp     event_wait              ; This is for ignored events, useful at development
 
;  *********************************************
;  ******  WINDOW DEFINITIONS AND DRAW  ********
;  *********************************************
;
;  The static window parts are drawn in this function. The window canvas can
;  be accessed later from any parts of this code (thread) for displaying
;  processes or recorded data, for example.
;
;  The static parts *must* be placed within the fn 12 , ebx = 1 and ebx = 2.
 
draw_window:
        mov     eax, 12                 ; function 12: tell os about windowdraw
        mov     ebx, 1                  ; 1, start of draw
        mcall
 
        mov     eax, 0                  ; function 0 : define and draw window
        mov     ebx, 100 * 65536 + xsize  ; [x start] *65536 + [x size]
        mov     ecx, 100 * 65536 + ysize  ; [y start] *65536 + [y size]
        mov     edx, 0x14ffffff         ; color of work area RRGGBB
                                        ; 0x02000000 = window type 4 (fixed size, skinned window)
        mov     esi, 0x808899ff         ; color of grab bar  RRGGBB
                                        ; 0x80000000 = color glide
        mov     edi, title
        mcall
 

        cmp [rd_err], 0
        je read_success
        mov     ebx, 25 * 65536 + 50    ;
        mov     ecx, 0x224466
        mov     edx, error_message
        mov     esi, len_error_message
        mov     eax, 4
        mcall
        mov     ebx, 200 * 65536 + 50    ;
        mov     ecx, 0x224466
        lea     edx, [filename]
        mov     esi, 256
        mov     eax, 4
        mcall
        jmp stop_drawing
        
        ; label
read_success:
        call set_position
        mov     ebx, eax
        mov     ecx, 0x224466
        mov     edx, txt_label
        mov     esi, len_label
        mov     eax, 4
        mcall

        mov dword [cursor_x],200
        call set_position
        mov     ebx, eax
        mov     ecx, 0x224466
        lea     edx, [extlabel]
        mov     eax, 4
        mov     esi,16
        mcall

        ; Draw the text labels  ; 
        ; Draw the feature values in hex for now.
        ; however we can map them to meaning full names too.
       
       ; compat
        mov dword [cursor_x],25
        mov dword [cursor_y],50
        call set_position
        mov     ebx, eax
        mov     ecx, 0x224466
        mov     edx, txt_compat
        mov     esi, len_compat
        mov     eax, 4
        mcall
        
        ; compat value
        mov dword [cursor_x],200
        call set_position
        mov     edx, eax
        mov     ebx, (8 shl 16) + 0x0100
        mov     ecx,[features.compat]
        mov     eax, 47
        mov     esi,16
        mcall

        ; compat names
        mov dword [cursor_x],150
        mov dword [cursor_y],70
        call set_position
        mov edi,[features.compat]
        mov esi,compat_table
        call iterate_features



        ; incompat
        mov dword [cursor_x],25
        mov ebx,[cursor_y]
        add ebx,15
        mov dword [cursor_y],ebx

        call set_position
        mov     ebx, eax
        mov     ecx, 0x224466
        mov     edx, txt_incompat
        mov     esi, len_incompat
        mov     eax, 4
        mcall

        ; incompat value
        mov dword [cursor_x],200
        call set_position
        mov edx, eax
        mov ebx, (8 shl 16) + 0x0100
        mov ecx,[features.incompat]
        mov esi,0x00FF0000
        mov eax,47
        mcall

        ; incompat names
        mov dword [cursor_x],100
        mov ebx,[cursor_y]
        add ebx,15
        mov dword [cursor_y],ebx

        mov edi,[features.incompat]
        mov esi,incompat_table
        call iterate_features


        ; ro_compat
        mov dword [cursor_x],25
        mov ebx,[cursor_y]
        add ebx,15
        mov dword [cursor_y],ebx

        call set_position
        mov     ebx, eax
        mov     ecx, 0x224466
        mov     edx, txt_ro_compat
        mov     esi, len_ro_compat
        mov     eax, 4
        mcall

        ; ro_compat value
        mov dword [cursor_x],200
        call set_position
        mov edx, eax
        mov eax,47
        mov ebx, (8 shl 16) + 0x0100
        mov ecx,[features.ro_compat]
        mov esi,0x00FF0000
        mcall

        ; ro_compat names
        mov dword [cursor_x],100
        mov ebx,[cursor_y]
        add ebx,15
        mov dword [cursor_y],ebx

        mov edi,[features.ro_compat]
        mov esi,ro_compat_table
        call iterate_features

stop_drawing:
        mov     eax, 12                 ; function 12:tell os about windowdraw
        mov     ebx, 2                  ; 2, end of draw
        mcall
 
        ret
 
;  *********************************************
;  *************   DATA AREA   *****************
;  *********************************************
 
title   db  "ext4 features reader", 0

txt_compat db "Compat Features:", 0
len_compat = $ - txt_compat

txt_incompat db "Incompat Features:", 0
len_incompat = $ - txt_incompat

txt_ro_compat db "RO Compat Features:", 0
len_ro_compat = $ - txt_ro_compat

txt_label db "Label:", 0
len_label = $ - txt_label

error_message db "Error reading file: ", 0
len_error_message = $ - error_message

; error code
rd_err dd ?
cursor_x dd 25
cursor_y dd 35

I_END:
        rb 4096
align 16
STACKTOP:

; each mask is of 32 bits
features:
    .compat dd 0
    .incompat dd 0
    .ro_compat dd 0

; 16 bytes label
extlabel:
        .label rb 16

file_read:
    .subfunction dd 0 ; for reading 
    .Offset dd super_block_offset + features_offset
    .Offset_1 dd 0 ; higher bytes 0
    .size dd num_of_bytes_in_feature_mask
    .return dd features
    db 0
    .name dd filename

filename db "/hd0/1/data/ext4.img",0



include "./table.inc"

MEM: