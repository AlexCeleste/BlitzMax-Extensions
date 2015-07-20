#if defined(__WIN32__) || defined(__APPLE__)
# define FUNC(s) _##s
#else
# define FUNC(s) s
#endif

.text
.globl FUNC(TLAMBDA_GetStart)
.globl FUNC(TLAMBDA_DoCall)
.globl FUNC(TLAMBDA_EndCall)
.globl FUNC(TLAMBDA_GetEBP)
.globl FUNC(TLAMBDA_GetESP)

FUNC(TLAMBDA_GetStart):
    mov 4(%ebp), %eax
    ret

FUNC(TLAMBDA_DoCall):
	mov (%esp), %eax
	mov 12(%esp), %ecx
	mov %eax, (%ecx)
	
	mov 16(%esp), %eax
	mov 20(%esp), %ecx
	mov %ebp, (%eax)
	mov %esp, (%ecx)
	addl $4, (%ecx)
	
	mov 4(%esp), %eax
	mov 8(%esp), %ecx
	sub $100, %esp
	jmp *%ecx
	ret

FUNC(TLAMBDA_EndCall):
	mov 4(%esp), %eax
	mov 8(%esp), %ebp
	mov 12(%esp), %esp
	jmp *%eax

FUNC(TLAMBDA_GetEBP):
	mov %ebp, %eax
	ret

FUNC(TLAMBDA_GetESP):
	mov %esp, %eax
	ret


