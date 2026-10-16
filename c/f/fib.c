#include <stdint.h>

int64_t fib(int64_t n) {
    if (n < 0 || n > 90) return -1;
    int64_t previous = 1, current = 2;
    for (int64_t i = 0; i < n; ++i) { int64_t next = previous + current; previous = current; current = next; }
    return previous;
}
