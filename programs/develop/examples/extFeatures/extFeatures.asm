;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                  ;
; FORK OF EXAMPLE APPLICATION Compile with FASM    ;
;                                                  ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This program will read the features bytes from an ext4 image given in cmd line 
; args in full path
; Usage 
; ./extFeatures /sys/ext4.img
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
dd I_Param
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


 
START:                 
        ; 1) Read the features from the ext4 image
        mov     eax, 70                 ; Function 70: File system operations
        mov     ebx, file_read          ; Pointer to the file_read struct
        mcall

        ; read label
        mov     eax, super_block_offset + label_offset
        mov     [file_read.Offset], eax

        mov     dword [file_read.size], 16

        lea     eax, [extlabel]
        mov     [file_read.return], eax

        mov     eax, 70
        mov     ebx, file_read         
        mcall

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
        mov     ebx, 100 * 65536 + 300  ; [x start] *65536 + [x size]
        mov     ecx, 100 * 65536 + 120  ; [y start] *65536 + [y size]
        mov     edx, 0x14ffffff         ; color of work area RRGGBB
                                        ; 0x02000000 = window type 4 (fixed size, skinned window)
        mov     esi, 0x808899ff         ; color of grab bar  RRGGBB
                                        ; 0x80000000 = color glide
        mov     edi, title
        mcall
 


        
        ; label
        mov     ebx, 25 * 65536 + 35    ;
        mov     ecx, 0x224466
        mov     edx, txt_label
        mov     esi, 12
        mov     eax, 4
        mcall
        mov eax,4
        mov ebx,200*65536 + 35
        mov ecx,0x224466
        lea edx, [extlabel]
        mov esi,16
        mcall

        ; Draw the text labels  ; 
        ; Draw the feature values in hex for now. however we can map them to meaning full names too.
       
       ; compat
        mov     ebx, 25 * 65536 + 65    ;
        mov     ecx, 0x224466
        mov     edx, txt_compat
        mov     esi, 12
        mov     eax, 4
        mcall
        mov eax,47
        mov ebx, (8 shl 16) + 0x0100
        mov ecx,[features.compat]
        mov edx, 200*65536 + 65
        mov esi,0x00FF0000
        mcall

        ; incompat
        mov     ebx, 25 * 65536 + 95    
        mov     ecx, 0x224466
        mov     edx, txt_incompat
        mov     esi, 18
        mov     eax, 4
        mcall
        mov eax,47
        mov ebx, (8 shl 16) + 0x0100
        mov ecx,[features.incompat]
        mov edx, 200*65536 + 95
        mov esi,0x00FF0000
        mcall


        ; ro_compat
        mov     ebx, 25 * 65536 + 125  
        mov     ecx, 0x224466
        mov     edx, txt_ro_compat
        mov     esi, 19
        mov     eax, 4
        mcall
        mov eax,47
        mov ebx, (8 shl 16) + 0x0100
        mov ecx,[features.ro_compat]
        mov edx, 200*65536 + 125
        mov esi,0x00FF0000
        mcall

        ; 
        
        mov     eax, 12                 ; function 12:tell os about windowdraw
        mov     ebx, 2                  ; 2, end of draw
        mcall
 
        ret
 
;  *********************************************
;  *************   DATA AREA   *****************
;  *********************************************
;
; Data can be freely mixed with code to any parts of the image.
; Only the header information is required at the beginning of the image.
 
title   db  "ext4 features reader", 0
txt_compat db "Compat Features:", 0
txt_incompat db "Incompat Features:", 0
txt_ro_compat db "RO Compat Features:", 0
txt_label db "Label:", 0
 
I_Param dd 0
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

filename db "/kolibrios/DVELOP/EXAMPLES/ext4.img", 0

MEM:

; The area after I_END is free for use as the application memory, 
; just avoid the stack.
;
; Application memory structure, according to the used header, 1 Mb.
;
; 0x00000   - Start of compiled image
; I_END     - End of compiled image           
;
;           + Free for use in the application
;
; STACKTOP  - Start of stack area               - defined in the header
; STACKTOP-4096 - End of stack area
;
;           + Free for use in the application
;
; MEM       - End of freely useable memory      - defined in the header
;
; All of the the areas can be modified within the application with a
; direct reference.
; For example, mov [STACKTOP-1],byte 1 moves a byte above the stack area.