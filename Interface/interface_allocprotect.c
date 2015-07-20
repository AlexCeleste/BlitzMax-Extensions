// Genericised alloc/protect for Windows+UNIX
// For allocating a code buffer then allowing it to run

#ifdef _WIN32
#  include <windows.h>
#else
#  include <sys/mman.h>
#endif

#ifdef _WIN32

void * tinterface_alloc(int sz) {
	return VirtualAlloc(0, sz, MEM_COMMIT | MEM_RESERVE, PAGE_EXECUTE_READWRITE);
}

int tinterface_reprotect(void * p, int sz) {
	DWORD _;
	return VirtualProtect(p, sz, PAGE_EXECUTE_READ, &_);
}

#else

#  ifdef __APPLE__
#    define MAP_ANONYMOUS MAP_ANON
#  endif

void * tinterface_alloc(int sz) {
	return mmap(0, sz, PROT_READ | PROT_WRITE | PROT_EXEC, MAP_ANONYMOUS | MAP_SHARED, -1, 0);
}

int tinterface_reprotect(void * p, int sz) {
	return mprotect(p, sz, PROT_READ | PROT_EXEC);
}

#endif

