
#if defined(__WIN32__) || defined(__APPLE__)
# define FUNC(s) _##s
#else
# define FUNC(s) s
#endif

.text
.globl FUNC(STRUCT_CheckEbp)

FUNC(STRUCT_CheckEbp):
    mov %ebp, %eax
    ret
