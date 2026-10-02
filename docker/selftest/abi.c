/* Compile-time checks that clang's armv7-none-eabi defaults match the QNX ARM
 * (AAPCS, softfp) ABI that BB10's libraries were built with, and calls that
 * need each ARM run-time ABI helper BB10's libc does not export. */

#include <stddef.h>
#include <string.h>

#define CHECK(name, cond) typedef char check_##name[(cond) ? 1 : -1]

#if !defined(__QNX__) || !defined(__QNXNTO__) || !defined(__unix__) || !defined(__ARM_EABI__)
#error "missing QNX/ARM EABI predefines"
#endif
#if defined(__ARM_PCS_VFP)
#error "BB10 uses the softfp calling convention, not hard-float"
#endif

enum small { SMALL_A };
CHECK(enum_is_int, sizeof(enum small) == 4);
CHECK(wchar_is_4, sizeof(L'x') == 4);
CHECK(pointer_is_4, sizeof(void *) == 4);
CHECK(size_t_is_4, sizeof(size_t) == 4);
CHECK(long_is_4, sizeof(long) == 4);
CHECK(long_long_align_8, __alignof__(long long) == 8);
CHECK(double_align_8, __alignof__(double) == 8);
CHECK(char_is_unsigned, (char)-1 > 0);

long long selftest_d2lz(double d) { return (long long)d; }
double selftest_l2d(long long x) { return (double)x; }
unsigned long long selftest_f2ulz(float f) { return (unsigned long long)f; }
unsigned long long selftest_uldivmod(unsigned long long a, unsigned long long b) { return a / b + a % b; }

void selftest_mem(void *dst, const void *src, size_t n) {
    memcpy(dst, src, n);
    memmove(dst, src, n);
    memset(dst, 1, n);
    memset(dst, 0, n);
}
