// Genericised alloc/protect for Windows+UNIX
// For allocating a code buffer then allowing it to run

#ifdef _WIN32
#  include <windows.h>
#else
#  include <sys/mman.h>
#endif

#ifdef _WIN32

int struct_protread(void) { return PAGE_READONLY; }
int struct_protreadwrite(void) { return PAGE_READWRITE; }

int struct_reprotect(void * p, int sz, int prot) {
	DWORD _;
	return VirtualProtect(p, sz, PAGE_EXECUTE_READ, &_);
}

#else

#  ifdef __APPLE__
#    define MAP_ANONYMOUS MAP_ANON
#  endif

int struct_protread(void) { return PROT_READ; }
int struct_protreadwrite(void) { return PROT_READ | PROT_WRITE; }

int struct_reprotect(void * p, int sz, int prot) {
	return mprotect(p, sz, prot);
}

#endif

