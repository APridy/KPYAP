.model small
.stack 100h   

.data       

welcome_message db 'Enter 5x6 matrix: $'
word_enter db 0dh, 0ah,'Enter $'
word_row db 'row: $'
end_message db 0dh, 0ah,'Sorted matrix:',0dh,0ah,'$' 

buffer_string db 200, 200 dup ('$')
final_string db 200, 200 dup ('$')

ctrlf db 0dh, 0ah, '$'   
symb db ?

num dw 49, '$'
cx_buf dw ? 
si_buf dw ?
di_buf dw ?
transit_swap db ?
len dw 3
round_count dw 0  

.code

proc enter_matrix
    entering:
    mov dx, offset word_enter ;vyvod 'Enter'
    int 21h

    add num, 1
    mov dx, offset num  ;vyvod nomera stroki
    int 21h 
 
    mov dx, offset word_row  ;vyvod 'Row'
    int 21h 

    mov dx, offset buffer_string    ;chtenie
    mov ah, 0ah
    int 21h 
                
    mov ah, 9
     
    ;mov dx, offset buffer_string + 2
    ;int 21h
    
    call set_len
    call sort 
    ;mov dx, offset ctrlf
    ;int 21h 
    ;mov dx, offset buffer_string + 2
    ;int 21h 
    
    call load_row 

    cmp cx,0
    je end_entering
    loop entering  
    end_entering:  
    ret
enter_matrix endp  

proc load_row
    mov cx_buf,cx
    mov cx,len
    lea si, buffer_string + 2    
    rep movsb
    
    mov cx,2
    lea si, ctrlf
    rep movsb 
     
    mov cx,cx_buf
    ret    
load_row endp

proc set_len
    mov si_buf, si 
    mov len,0   
    mov si, 3 
    
    dont_leave:
    cmp buffer_string[si] , '$'
    je leave
    inc si
    inc len 
    jmp dont_leave 
    
    leave:
    mov si, si_buf
    ret    
set_len endp 

proc sort
    mov si_buf, si 
    mov di_buf, di
    mov cx_buf, cx 
    add len,2
     
    mov round_count,6 
    round:
    mov cx,5
    mov si,2
    mov di,4      
    
    dont_leave1:  
    
    mov dl, buffer_string[di] 
    cmp buffer_string[si], dl 
    ja swap
    continue:
    add si,2
    add di,2 
    
    loop dont_leave1
    dec round_count
    cmp round_count,0
    jne round
     
    jmp leave1
    
    swap:
    mov dh, buffer_string[di]
    mov dl, buffer_string[si]
    mov buffer_string[di], dl
    mov buffer_string[si], dh
    jmp continue 
    
    
    leave1:
    sub len,2
    mov cx,cx_buf
    mov di,di_buf 
    mov si,si_buf
    ret        
sort endp

start:    
    mov ax, @data
    mov ds, ax
    mov es, ax 
    xor si,si 
    xor di,di
    mov cx, 5    

    mov dx, offset welcome_message   
    mov ah, 9
    int 21h  

    mov num, 48   
    
    lea di, final_string  

    call enter_matrix

    mov dx, offset end_message
    mov ah, 9
    int 21h 
 
    mov dx, offset final_string 
    mov ah, 9
    int 21h 

    mov ax, 4c00h
    int 21h  

end start 



    

