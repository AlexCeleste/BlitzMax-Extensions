#if defined(__WIN32__) || defined(__APPLE__)
# define FUNC(s) _##s
#else
# define FUNC(s) s
#endif

.text
.globl FUNC(TLAMBDA_GetStart)
.globl FUNC(TLAMBDA_AllocFrame)
//.globl FUNC(TLAMBDA_CalleeSave)
.globl FUNC(TLAMBDA_GetHostESP)
.globl FUNC(TLAMBDA_DoCall)
.globl FUNC(TLAMBDA_EndCall)

.globl FUNC(bbMemAlloc)

FUNC(TLAMBDA_GetStart):  //(void * frame, tmpesi, tmpedi)
        mov 4(%esp), %edx
        add $24, %edx
        // Temporarily save the callee-save registers
        mov %esi, 8(%esp)
        mov %edi, 12(%esp)
        // Temporarily store the frame ptrs
        mov %ebp, %esi
        mov %esp, %edi
        // Pop FN_Make() and its wrapper off the stack to get host frame
        mov %ebp, %esp
        pop %ebp
        mov %ebp, %esp
        pop %ebp
        // Save the host stack frame
	mov %ebp, %ecx
        sub %esp, %ecx
        mov %ecx, (%edx)    // Save the frame size
        cmp $0, %ecx
        je _end_gs
        add $4, %edx
        mov %esp, %ecx
    _top_gs:
        mov (%ecx), %eax
        mov %eax, (%edx)
        add $4, %ecx
        add $4, %edx
        cmp %ebp, %ecx
        jne _top_gs
    _end_gs:
        // Return the return pointer
        mov (%esp), %eax
        // Restore the frame pointers and index registers
        mov %esi, %ebp
        mov %edi, %esp
        mov 8(%esp), %esi
        mov 12(%esp), %edi
        ret

FUNC(TLAMBDA_AllocFrame):     //(size)
	push %ebp
	mov %esp, %ebp
	sub $16, %esp
        mov %ebx, 4(%esp)
        mov %esi, 8(%esp)
        mov %edi, 12(%esp)
        mov 8(%ebp), %eax
	mov %eax, (%esp)
	call FUNC(bbMemAlloc)
	mov 4(%esp), %ebx
        mov %ebx, (%eax)
        mov 8(%esp), %esi
        mov %esi, 4(%eax)
        mov 12(%esp), %edi
        mov %edi, 8(%eax)
	mov %ebp,%esp
	pop %ebp
	ret

//FUNC(TLAMBDA_CalleeSave):   //(&frame)
//        mov 4(%esp), %eax
//        mov %ebx, (%eax)
//        mov %esi, 4(%eax)
//        mov %edi, 8(%eax)
//        ret

FUNC(TLAMBDA_GetHostESP):
        mov %esp, %ecx
        mov %ebp, %edx
        // Pop FN_Make() and its wrapper off the stack to get host frame
        mov %ebp, %esp
        pop %ebp
        mov %ebp, %esp
        pop %ebp
        mov %esp, %eax
        mov %ecx, %esp
        mov %edx, %ebp
        ret

FUNC(TLAMBDA_DoCall):  //(void * frame, void * ins, Self, &RET, &EBP, &ESP)
        mov (%esp), %eax    // ret -> *RET
        mov 16(%esp), %ecx
        mov %eax, (%ecx)
        mov 20(%esp), %eax  // ebp -> *EBP
        mov %ebp, (%eax)
        mov 24(%esp), %ecx  // esp -> *ESP
        mov %esp, (%ecx)
        //
        mov 4(%esp), %edx   // frame
        // Save the local callee-save registers
        mov %ebx, 12(%edx)
        mov %esi, 16(%edx)
        mov %edi, 20(%edx)
        // Restore the callee-save registers
        mov (%edx), %ebx
        mov 4(%edx), %esi
        mov 8(%edx), %edi
        add $24, %edx
        // Restore the stack frame pointers
        push %ebp
        mov %esp, %ebp
        sub (%edx), %esp
        // Restore the stack frame content
        mov (%edx), %eax
        cmp $0, %eax
        je _end_dc
        add $4, %edx
        mov %esp, %ecx
    _top_dc:
        mov (%edx), %eax
        mov %eax, (%ecx)
        add $4, %ecx
        add $4, %edx
        cmp %ebp, %ecx
        jne _top_dc
    _end_dc:
        mov 12(%ebp), %ecx  // Jump to saved instruction
        mov 16(%ebp), %eax
        jmp *%ecx
        //

FUNC(TLAMBDA_EndCall):  // (RETP, EBP, ESP, void * frame)
        // Restore the local callee-save registers
        mov 16(%esp), %edx
        mov 12(%edx), %ebx
        mov 16(%edx), %esi
        mov 20(%edx), %edi
	mov 4(%esp), %ecx
	mov 8(%esp), %ebp
	//mov 20(%esp), %eax
        mov 12(%esp), %esp
        add $4, %esp    // esp was stored after a call so it's off by one
	jmp *%ecx
