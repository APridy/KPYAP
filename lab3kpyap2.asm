.model small
.stack 100h   

.data       

welcome_message db 'Enter 5x6 matrix $'
enter_word db 0dh, 0ah, 'Enter $'  ;removed ,
row_word db 'row: $'
final_message db 0dh, 0ah,'Sorted matrix:',0dh, 0ah, '$'  
error_message db 0dh, 0ah,'Trash in row. Re-enter row:' ,0dh, 0ah, '$'  ;removed ,
buffer_string db 200, 200 dup ('$')
final_string  db 250, 250 dup ('$') 
newline db 0dh, 0ah, '$'   
symb db ? , '$'
si_buf dw ?   
di_buf dw ?

final_si dw 2

row_count dw ?

first_number dw ?
second_number dw ? 
 
first_number_polarity dw ?
second_number_polarity dw ? 

first_number_length dw ?
second_number_length dw ? 

numbers_length dw ?

swap dw ?  
sort_count dw 6
swap_count dw 5 
swap_interval dw ?


swapping_si dw ?
swapping_di dw ?
swapping_first_number_length dw ?
swapping_second_number_length dw ?
swapping_end dw ?
swapping_beginning dw ?  

letter_shift_count dw ?

num dw 48, '$'  
ten dw 10
zero dw 0
 
len dw ?
space_count dw ?
word_letters_count dw ?


.code 
   
proc enter_string         
    mov dx,offset buffer_string
    mov ah,0ah
    int 21h  
    mov ah,9    
    ret
enter_string endp   

proc print_string
    mov si,2
    mov cx,len

    mov ah,9   

    mov dx,offset newline
    int 21h 

    print_by_symb:
        mov bl,  buffer_string[si] 
        mov symb, bl 
        mov dx,offset symb 
        int 21h   
        inc si
    loop print_by_symb  

    ret    
print_string endp 

proc renew_string 
    mov si,2
    mov cx,200
      
    replace_with_end: 
    mov buffer_string[si], '$'   
    inc si
    loop replace_with_end    
    ret    
renew_string endp
                 
proc get_len
    mov si,2
    mov len,0  
    check_if_end: 
    
    inc si  
    inc len 

    cmp buffer_string[si], '$'  
    jne check_if_end 
    dec len    
    ret           
endp get_len 
    

proc seek_for_trash 
    sft_beginning:
    mov space_count,0
    mov word_letters_count,0
    mov si,1
    check_if_end2: 
    inc si 
          
    cmp buffer_string[si], '$' 
    je leave 
    
    cmp buffer_string[si], 0dh
    je leave  
                               
    cmp buffer_string[si], 0ah 
    je leave      
    
    cmp buffer_string[si], ' '
    je check_if_space_correct 
    
    cmp buffer_string[si], '-'
    je check_if_minus_correct  
    
    cmp buffer_string[si], '/'
    jbe leave_bad
    
    cmp buffer_string[si], ':'
    jae leave_bad   
    
    inc word_letters_count
    
    cmp word_letters_count,5  
    mov si_buf,si
    jne skip_checking_for_overflow
      
      
        
        sub si,4 
        cmp buffer_string[si], '3'
        ja leave_bad
        jb skip_checking_for_overflow  
        
        inc si
        cmp buffer_string[si], '2'
        ja leave_bad 
        jb skip_checking_for_overflow
        
        inc si
        cmp buffer_string[si], '7'
        ja leave_bad
        jb skip_checking_for_overflow
         
        inc si    
        cmp buffer_string[si], '6'
        ja leave_bad 
        jb skip_checking_for_overflow
        
        cmp si,5
        je skip_checking_for_minus 
        
        sub si,4
        cmp buffer_string[si], '-' 
        jne return_to_si_plus_4
         
        add si,5 
        cmp buffer_string[si], '7'
        ja leave_bad 
        jmp skip_checking_for_overflow  
        
        return_to_si_plus_4: 
        add si,4 
        
        skip_checking_for_minus:
        inc si  
        cmp buffer_string[si], '8'
        ja leave_bad   

    skip_checking_for_overflow:
    mov si,si_buf
    cmp word_letters_count,6
    je leave_bad
    
    jmp check_if_end2
    
    leave:
    cmp space_count,5
    jne leave_bad
    ret              
    
    check_if_space_correct:
        mov word_letters_count,0 
        inc space_count
        cmp si,2
        je leave_bad  
        
        dec si
        cmp buffer_string[si], ' '
        je leave_bad 
        inc si
         
        inc si
        cmp buffer_string[si], ' '
        je leave_bad   
        
        cmp buffer_string[si], '0'              ;;;;;
        jne skip_checking_for_unreasonable_zero ;;;;; 
        inc si 
        cmp buffer_string[si], ' '
        je skip_checking_for_unreasonable_zero
        cmp buffer_string[si], 0dh
        jne leave_bad:
        dec si                                  ;;;;;
        skip_checking_for_unreasonable_zero:    ;;;;;
         
        cmp buffer_string[si], 0dh 
        je leave_bad
        dec si
        
    jmp check_if_end2 
    
    check_if_minus_correct:
        mov word_letters_count,0
        cmp si,2
        je skip_minus_front_checking  
        
        dec si
        cmp buffer_string[si], ' '
        jne leave_bad 
        inc si
         
        skip_minus_front_checking:
        inc si
        cmp buffer_string[si], ' '
        je leave_bad
        cmp buffer_string[si], '0';;;;;
        je leave_bad              ;;;;;
        cmp buffer_string[si], 0dh 
        je leave_bad
        dec si
    jmp check_if_end2 
    
    leave_bad:
    call renew_string 
    
    mov ah,9
      
    mov dx,offset error_message 
    int 21h
    
    call enter_string
      
    jmp sft_beginning
     
    ret
seek_for_trash endp

proc sort 
    mov sort_count, 6
    sorting_6_times: 
     
    mov first_number_polarity, 1
    mov second_number_polarity, 1    
    mov si,2
    mov di,2    

    cmp buffer_string[si], '-'
    jne skip_adding_1_to_si
    inc si
    inc di 
    mov first_number_polarity, 0  
    
    skip_adding_1_to_si:    
    call set_first_number_length 
    
    mov swap_count, 5
    swapping_5_times:
        call set_second_number_length
        call compare
    
        cmp swap, 1
        jne skip_swapping_numbers 
    
        call swapping
        ;;;;;
       ; mov ah, 9   
       ; mov dx, offset newline
       ; int 21h
                                          ; to see every change
       ; mov ah, 9   
       ; mov dx, offset buffer_string + 2
        ;int 21h 
        ;;;;;       
        jmp skip_assigning_if_not_swapping   
        
        skip_swapping_numbers: 
    
        mov si,di
        
        mov ax, second_number_length
        mov first_number_length,ax 
        mov ax, second_number_polarity
        mov first_number_polarity,ax   
        
        skip_assigning_if_not_swapping:   
        
        dec swap_count
        cmp swap_count, 0
    jne swapping_5_times:
    
     dec sort_count
     cmp sort_count, 0
     jne sorting_6_times:
    
    ret    
sort endp   


proc set_first_number_length
    mov si_buf,si
    mov first_number_length,0 
     
    checking_for_end1:
    cmp buffer_string[si], ' '
    je leave_fnl       
    cmp buffer_string[si], 0dh
    je leave_fnl
    
    
    inc first_number_length 

    inc si
    jmp checking_for_end1
    
    leave_fnl:
    mov si,si_buf
    ret    
set_first_number_length endp


proc set_second_number_length
    mov second_number_polarity,1 
    mov second_number_length,0   
    
    add di, first_number_length
    inc di
     
    cmp buffer_string[di], '-'  
    jne skip_adding_1_to_di 
    inc di
    mov second_number_polarity,0
    skip_adding_1_to_di: 
    mov di_buf, di
    
    checking_for_end2:
    cmp buffer_string[di], ' '
    je leave_snl       
    cmp buffer_string[di], 0dh
    je leave_snl
    
    
    inc second_number_length 
    inc di
    jmp checking_for_end2 
           
    leave_snl: 
    mov di,di_buf
    ret
set_second_number_length endp

proc compare        
    
    mov ax,second_number_polarity 
    
    cmp first_number_polarity, ax
    ja first_bigger 
    jb second_bigger
    cmp first_number_polarity, 1
    je compare_if_positive
    jne compare_if_negative 
    
    compare_if_positive:  
    
        mov ax,second_number_length 
    
        cmp first_number_length, ax
        ja first_bigger
        jb second_bigger
        
        
        mov ax, first_number_length
        mov numbers_length,ax
        mov di_buf,di
        mov si_buf,si
        comparing_two_length_equal_positive_numbers:
        
        mov al, buffer_string[di]
        cmp buffer_string[si], al      
        ja first_bigger_with_buf 
        jb second_bigger_with_buf 
      
        
        jmp skip_equal_positive_bigger_options
        first_bigger_with_buf:
            mov si,si_buf
            mov di,di_buf
            jmp first_bigger
        second_bigger_with_buf: 
            mov si,si_buf
            mov di,di_buf
            jmp second_bigger
        skip_equal_positive_bigger_options:
        
        inc si
        inc di 
        dec numbers_length
        cmp numbers_length,0
             
        jne comparing_two_length_equal_positive_numbers
        skip_comparing_two_length_equal_positive_numbers: 
        
        mov si,si_buf
        mov di,di_buf
        jmp end_comparing
    
    
    compare_if_negative:    
    
        mov ax,second_number_length

        cmp first_number_length, ax
        ja second_bigger
        jb first_bigger
        
        mov ax, first_number_length
        mov numbers_length,ax
        mov di_buf,di
        mov si_buf,si
        comparing_two_length_equal_negative_numbers:
        
        mov al, buffer_string[di]
        cmp buffer_string[si], al      
        ja second_bigger_with_buf 
        jb first_bigger_with_buf 
        
        inc si
        inc di 
        dec numbers_length
        cmp numbers_length,0
             
        jne comparing_two_length_equal_negative_numbers
        skip_comparing_two_length_equal_negative_numbers: 
        
        mov si,si_buf
        mov di,di_buf
        jmp end_comparing
    
    
    second_bigger:
    mov swap,0
    jmp end_comparing 
     
    first_bigger:
    mov swap,1
    jmp end_comparing 
    
    both_equal:
    mov swap,0
    jmp end_comparing 
    
    end_comparing:
    ret
compare endp

proc swapping  
   mov swapping_si,si
   mov swapping_di,di 
   
   mov ax, first_number_length 
   mov swapping_first_number_length, ax
   mov ax, second_number_length     
   mov swapping_second_number_length, ax 
    
   cmp first_number_polarity, 1
   je skip_decreasing_swapping_si
   dec swapping_si
   inc swapping_first_number_length
   skip_decreasing_swapping_si:   
   
   cmp second_number_polarity, 1
   je skip_adding_swap_interval_and_decreasing_swapping_di  
   inc swap_interval   
   dec swapping_di 
   inc swapping_second_number_length
   skip_adding_swap_interval_and_decreasing_swapping_di:
   
   add si, swapping_second_number_length
   inc si
   mov di,si
     
   mov ax,swapping_di
   mov swap_interval,ax
   
   mov ax,swapping_si 
   sub swap_interval,ax 
   
   mov ax, swapping_di
   add ax, swapping_second_number_length
   mov swapping_end,ax 
   
   mov ax, swapping_si
   add ax, swapping_first_number_length
   mov swapping_beginning,ax
   
   mov ax,swapping_end
   sub ax,swapping_beginning
   mov letter_shift_count, ax 
   
   swapping_numbers_by_letter:
   
   dec swapping_end
   dec swapping_beginning 
   
   mov bx, swapping_beginning
   mov al, buffer_string[bx]
       
       mov dx,letter_shift_count
       shifting_letters: 
       
       inc bx
       mov ah, buffer_string[bx] 
       dec bx
       mov buffer_string[bx],ah
       inc bx
       
       dec dx
       cmp dx,0 
       jne shifting_letters 
   
   cmp swap_interval,1
   jne skip_anti_bug
   mov al,32
   skip_anti_bug:    
   mov bx, swapping_end
   mov buffer_string[bx],al
   
   ;mov ah, 9   
   ;mov dx, offset newline
   ;int 21h
                                          ; to see every change
   ;mov ah, 9   
   ;mov dx, offset buffer_string + 2
   ;int 21h      

   dec swap_interval
   cmp swap_interval, 0
   jne swapping_numbers_by_letter 
   
   ret 
swapping endp

proc load_row 
    
    mov si_buf,si
    
    mov si,2  
    loading_row:
    cmp buffer_string[si], 0dh 
    je stop_loading_in_row  
        
    mov al, buffer_string[si]
    mov bx,final_si  
    mov final_string[bx],al
     
    inc final_si 
    inc si  
    jmp loading_row
    
    stop_loading_in_row:
    
    mov bx,final_si
    mov final_string[bx],0dh
    
    inc final_si 
    mov bx,final_si
    mov final_string[bx],0ah
    
    inc final_si
     
    mov si,si_buf
    ret
load_row endp

start:
    mov ax, @data
    mov ds, ax
    mov es, ax 
    xor si,si 
    xor di,di  
      
    mov ah,9
    mov dx,offset welcome_message
    int 21h
    
    mov row_count,5  
    enter_row: 
    inc num
    
    mov ah,9
    mov dx,offset enter_word 
    int 21h
    
    mov dx,offset num
    int 21h 
    
    mov dx,offset row_word 
    int 21h
    
    mov dx,offset newline 
    int 21h
             
    call enter_string 
    call seek_for_trash
    call get_len
    call sort 
    call load_row
    call renew_string
     
    dec row_count
    cmp row_count,0
    jne enter_row
                                       
    mov ah,9 
    
    mov dx,offset final_message
    int 21h  
    
    mov dx,offset final_string + 2
    int 21h 
                  
    mov ax, 4c00h
    int 21h  
                    
end start
 
 

