
// mmap/mprotect/munmap (or equivalent) wrappers
// for allocating pages and changing their protections

#ifdef _WIN32
#  include <windows.h>
#else
#  include <sys/mman.h>
#include <signal.h>
#endif

#ifdef _WIN32

void * aspect_mmap(int sz) {
	return VirtualAlloc(0, sz, MEM_COMMIT | MEM_RESERVE, PAGE_EXECUTE_READWRITE);
}

int aspect_mprotect_rwx(void * p, int sz) {
	DWORD _;
	return VirtualProtect(p, sz, PAGE_EXECUTE_READWRITE, &_);
}

#else

#if __APPLE__ && __MACH__
#  define MAP_ANONYMOUS MAP_ANON
#endif

void * aspect_mmap(size_t sz) {
	return mmap(0, sz, PROT_READ | PROT_WRITE, MAP_ANONYMOUS | MAP_SHARED, -1, 0);
}

int aspect_mprotect_rwx(void * p, size_t sz) {
	return mprotect(p, sz, PROT_READ | PROT_WRITE | PROT_EXEC);
}

#endif

