
;------------------------------------------------------- 
; we can iterate the table <mask,string_pointer>  End Of Table is 0
; for each feature_mask iterate the table and print the string if the bit is set
; 

; iterate_features(value, table)
; edi = value  
; esi = pointer to table
; return eax = number of features printed

iterate_features:
    xor ecx, ecx            ; count = 0

.loop:
    mov ebx, [esi]          ; load feature mask
    test ebx, ebx
    jz .done                ; end (0 terminator)

    test edi, ebx
    jz .next                ; skip if not set

    pusha
    mov edi, esi      ; string ptr
    call print_pair
    popa

    inc ecx

.next:
    add esi, 8              ; next entry
    jmp .loop

.done:
    mov eax, ecx
    ret


; print_string(ptr to table)
; edi = pointer to table entry

print_pair:

    ; print bit mask
    call set_position       ; eax = packed pos
    mov edx, eax
    mov eax, 47             ; syscall
    mov ecx, [edi]        ; hex value
    mov ebx,(8 shl 16) + 0x0100
    mov esi, 16
    mcall


    ; print string
    mov ebx, [cursor_x]
    add ebx, 100
    mov [cursor_x], ebx
    call set_position
    mov ebx, eax
    mov ecx, 0x80000000
    mov edx, [edi+4] ; string ptr
    mov eax, 4
    mcall

    ; update Y cursor
    mov ebx, [cursor_y]
    add ebx, 20
    mov [cursor_y], ebx
    mov [cursor_x], 150
    ret


; returns eax = (x << 16) | y

set_position:
    mov eax, [cursor_x]
    shl eax, 16
    add eax, [cursor_y]
    ret