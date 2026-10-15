#include <stdint.h>
static int64_t solve(int64_t n) {
    if (n == 0) return 2;
    if (n == 1) return 1;
    return solve(n - 1) + solve(n - 2);
}
int64_t lucas_series_recursive(int64_t n) {
    if (n < 0 || n > 25) return -1;
    return solve(n);
}
