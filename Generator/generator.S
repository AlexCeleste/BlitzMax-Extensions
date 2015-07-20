#if defined(__WIN32__) || defined(__APPLE__)
# define FUNC(s) _##s
#else
# define FUNC(s) s
#endif

.text
.globl FUNC(GENERATOR_Yield2)
.globl FUNC(GENERATOR_Resume)
.globl FUNC(GENERATOR_CalleeSave)

// Also unwinds the frame of the wrapping BM func
FUNC(GENERATOR_Yield2):  //(void * frame, void ** ins, void * val)
        // Save the return pointer
	mov 4(%ebp), %eax
        mov 8(%esp), %edx
	mov %eax, (%edx)
        // Save the gen's callee-save registers
        mov 4(%esp), %edx
        mov %ebx, (%edx)
        mov %esi, 4(%edx)
        mov %edi, 8(%edx)
        // Restore the local callee-save registers
        mov 12(%edx), %ebx
        mov 16(%edx), %esi
        mov 20(%edx), %edi
        add $24, %edx
        // Save the yield value
        mov 12(%esp), %eax
        mov %eax, (%edx)  // Not keeping this
        // Pop the call to the Yield wrapper
        mov %ebp, %esp
        pop %ebp
        // Put the yield value in the now-redundant arg slots
        mov (%edx), %eax
        mov %eax, -4(%esp)
        // Save the stack frame
	mov %ebp, %ecx
        sub %esp, %ecx
        mov %ecx, (%edx)    // Save the frame size
        cmp $0, %ecx
        je _end_y
        add $4, %edx
        mov %esp, %ecx
    _top_y:
        mov (%ecx), %eax
        mov %eax, (%edx)
        add $4, %ecx
        add $4, %edx
        cmp %ebp, %ecx
        jne _top_y
    _end_y:
        // Return the Yield value
        mov -4(%esp), %eax
        mov %ebp, %esp  // return *from caller*
        pop %ebp
	ret

FUNC(GENERATOR_CalleeSave): //(void * frame)
        mov 4(%esp), %edx
        // Save local callee-save registers
        mov %ebx, 12(%edx)
        mov %esi, 16(%edx)
        mov %edi, 20(%edx)
        ret

FUNC(GENERATOR_Resume):  //(void * frame, void ** ins)
        mov 4(%esp), %edx
        push %ebp
        mov %esp, %ebp
        // Save local callee-save registers
        mov %ebx, 12(%edx)
        mov %esi, 16(%edx)
        mov %edi, 20(%edx)
        // Restore the gen's callee-save registers
        mov (%edx), %ebx
        mov 4(%edx), %esi
        mov 8(%edx), %edi
        add $24, %edx
        // Restore the stack frame pointers
        mov %ebp, %esp
        sub (%edx), %esp
        // Restore the stack frame content
        mov (%edx), %eax
        cmp $0, %eax
        je _end_r
        add $4, %edx
        mov %esp, %ecx
    _top_r:
        mov (%edx), %eax
        mov %eax, (%ecx)
        add $4, %ecx
        add $4, %edx
        cmp %ebp, %ecx
        jne _top_r
    _end_r:
        mov 12(%ebp), %eax  // Return to saved instruction
        jmp *%eax
        //
