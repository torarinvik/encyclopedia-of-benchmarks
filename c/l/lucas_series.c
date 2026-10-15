#include <stdint.h>
int64_t lucas_series(int64_t n) {
    if (n < 0 || n > 90) return -1;
    if (n == 0) return 2;
    int64_t previous = 2, current = 1;
    for (int64_t i = 2; i <= n; ++i) { int64_t next = previous + current; previous = current; current = next; }
    return current;
}
