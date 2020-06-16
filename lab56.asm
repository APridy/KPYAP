.model small
.stack 100h  
.data          

welcome_message db 'Welcome to odd word deleter','$' 
newline db 0dh,0ah,'$'
needed_symbols_message db 'Needed symbols: ','$'
good_message db 'Succesfully deleted all odd words.','$'
error_message db 'Error! Incorrect file name\address','$'
press_any_key  db  "Press any key to exit...", '$'
is_word_odd dw 1
file_name db  80 dup(0)
buf dw 0,'$'
space db ' ','$'
s_count dw 0,'$'
symbols dw 0,'$'  
file_descriptor dw 0 
reading_val db 200 dup('$')
file_read_position dd 00000000h
file_read_position1 dd 00000000h  
tracker dd 0
back_tracker dd 0
buf_tracker dd 0  
is_writing_word dw 0 
was_it_end dw 0

.code

get_name proc
    push ax 
    push cx
    push di
    push si
    xor cx, cx
    mov cl, es:[80h]    ;amount of symbols in cmd line
    cmp cl, 0
    je end_get_name
    mov di, 82h         ;offset of cmd line in PSP block
    lea si, file_name    ;load file name in si
cicle1:
    mov al, es:[di]     ;load in AL the value of of cmd line char by char
    cmp al, 0Dh         ;enter 
    je end_get_name
    mov [si], al        ;load symbol from cmd line in file name 
    inc di              ;for next symbol
    inc si            
    jmp cicle1 
end_get_name:        
    pop si          
    pop di
    pop cx
    pop ax   
ret
get_name endp 
 
 
proc delete_odds_from_file 

    mov bx,ax 
    m_loop:
    call read_next_symbol   
 
    cmp ax,0
    je break 
    inc symbols

    cmp buf, 0ah
    jne setting_odd_for_new_string
    mov is_word_odd,1
    jmp m_loop
    setting_odd_for_new_string:
    
    cmp buf, ' '
    je m_loop
  
    call delete_word

    jmp m_loop 
    
    break: 
    
    ret
delete_odds_from_file endp   
   
proc read_next_symbol
    mov ah, 3Fh
    mov cx, 1
    mov dx, offset buf 
    mov bx, file_descriptor
    int 21h
    ret
read_next_symbol endp 

proc delete_word    
    
    dec symbols 
    call move_backward
     
    deleting_loop: 
    call read_next_symbol
    
    cmp ax,0
    je shifting_words    
    
    inc symbols
     
    
    cmp buf, ' ' 
    je stop_deleting
    cmp buf, 0ah 
    je stop_deleting 
     
    
    cmp is_word_odd,1
    jne deleting_loop
     
    call move_backward
    mov cx,1
    mov dx, offset space 
    mov ah, 40h
    int 21h

    jmp deleting_loop 
    stop_deleting:  
  
    inc s_count 
       
    cmp buf,0ah
    je make_word_odd_because_newline
     
    cmp is_word_odd,0   
    je make_word_odd
    mov is_word_odd,0
    jmp skip_oddness 
    make_word_odd:
    mov is_word_odd,1
    skip_oddness:
    ret
    
    make_word_odd_because_newline:
    mov is_word_odd,1
    
    ret
delete_word endp
   
proc move_backward
    mov ah,42h  
    mov cx,0  
    NOT cx
    mov dx,1
    NOT dx
    inc dx
    mov al,1
    int 21h
    ret   
move_backward endp 

proc move_forward
    mov ah,42h  
    mov cx,0    
    mov dx,1
    mov al,1
    int 21h
    ret   
move_forward endp 

proc move_pointer
    mov ah,42h  
    mov cx,0   
    mov al,0
    int 21h
    ret       
move_pointer endp 

proc move_pointer_back_tracker
    mov ah,42h 
    mov cx, word ptr [back_tracker + 2]
    mov dx, word ptr [back_tracker] 
    mov bx,file_descriptor   
    mov al,0
    int 21h 
    ret       
move_pointer_back_tracker endp    

proc move_pointer_tracker 
    mov ah,42h 
    mov cx, word ptr [tracker + 2]
    mov dx, word ptr [tracker] 
    mov bx,file_descriptor   
    mov al,0
    int 21h 
    ret   
move_pointer_tracker endp 

proc cut_file
    mov ah,40h
    mov cx,0
    int 21h
    ret
cut_file endp 

proc shift_words
    mov tracker,0
    mov back_tracker,0
    mov buf,0
    shifting: 
    
    cmp was_it_end,0
    je dont_skip_spaces 
    skipping_spaces_loop:
    
    call move_pointer_tracker 
    call read_next_symbol  
    cmp ax,0
    je stop_shifting_words
    inc tracker    
    cmp tracker,0
    jne not_zero_tracker1
    inc tracker + 2
    not_zero_tracker1:
     
    cmp buf, ' ' 
    
    je skipping_spaces_loop   
    
    dec tracker
    cmp tracker,65535
    jne not_zero_tracker2
    dec tracker + 2
    not_zero_tracker2:
    ;call move_backward
    ;call move_backward
    
    mov was_it_end,0
    dont_skip_spaces:  
    
    call move_pointer_tracker 
    call read_next_symbol 
    inc tracker
    
    cmp tracker,0
    jne not_zero_tracker
    inc tracker + 2
    not_zero_tracker: 
    
    cmp ax,0
    je stop_shifting_words
    
    cmp buf,' ' 
    je is_space
    cmp buf,0ah
    jne not_end
    mov was_it_end,1
    not_end:   
     
    mov is_writing_word,1
   
    call move_pointer_back_tracker 
    
    mov cx,1
    mov dx, offset buf
    mov ah, 40h
    int 21h    
 
    inc back_tracker
    
    cmp back_tracker,0
    jne not_zero_back_tracker1
    inc back_tracker + 2
    not_zero_back_tracker1:
    
    jmp shifting
    is_space:  
    
    cmp is_writing_word,1
    jne shifting    
    
    mov is_writing_word,0

    call move_pointer_back_tracker 
    inc back_tracker 
   
    cmp back_tracker,0
    jne not_zero_back_tracker
    inc back_tracker + 2
    not_zero_back_tracker:
     
    mov cx,1
    mov dx, offset space
    mov ah, 40h
    int 21h   
     
    jmp shifting  
    
    stop_shifting_words: 
 
    mov dx, back_tracker
    call move_pointer_back_tracker
    call cut_file 
    
    ret    
shift_words endp 

start: 
    
    mov ax, @data                   
    mov ds, ax  
    
    mov ah,9 
    mov dx,offset welcome_message
    int 21h 
    
    mov ah,9 
    mov dx,offset newline
    int 21h    
    
    call get_name
    
    mov ah,3Dh           
    mov al,02h 
    mov dx,offset file_name          
    int 21h
    
    jnc continue  
    
    mov ah, 9
    mov dx, offset error_message
    int 21h
    mov dx, offset newline
    int 21h
    jmp exit     
             
    continue: 
    
    mov file_descriptor, ax  
    mov bx,ax
    call delete_odds_from_file    
   
shifting_words:
   
        call shift_words 
     
close_file:   
        
        mov ah,3Eh ;close file
        int 21h    

        mov ah, 09h   
        mov dx, offset good_message
        int 21h
       
        mov dx,offset newline
        int 21h
        mov dx, offset press_any_key
        int 21h
        mov dx,offset newline 
        int 21h  
        
        mov ah, 00h ;waiting for any key 
        int 16h 
       
exit:      
        mov ax, 4C00h ;exit program
        int 21h
buffer:


end start