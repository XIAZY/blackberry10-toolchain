/*
 * The stack protector's runtime for QNX 6.5.0, whose libc has none.
 *
 * qnx65-cc compiles without the stack protector, but the SDK's static libc
 * (libc.a, libcS.a), which holds the functions the shared one lacks (regcomp,
 * scandir, popen, ...), was built with it. A program that pulls one of those
 * in needs these two symbols, and must not take them from BB10's libc.so:
 * 6.5.0's does not have them. So qnx65-cc links this object into every
 * program and shared library. The definitions are hidden, so each has its
 * own, and weak, so a project's own definitions replace them. The guard is a
 * fixed terminator canary (a NUL, a newline and 0xff stop string copies), not
 * a random one.
 */
#include <stdlib.h>
#include <unistd.h>

__attribute__((weak, visibility("hidden"))) unsigned long __stack_chk_guard = 0xff0a0d00UL;

__attribute__((weak, visibility("hidden"))) void __stack_chk_fail(void)
{
    static const char message[] = "stack smashing detected\n";

    write(2, message, sizeof message - 1);
    abort();
}
