#include <stddef.h>
#include <stdint.h>
static int64_t josephus_solve(int64_t n, int64_t step) {
    if (n == 1) return 0;
    return (josephus_solve(n - 1, step) + step % n) % n;
}
int64_t josephus_problem_recursive(const int64_t *values, size_t length) {
    if (length != 2) return -1;
    const int64_t n = values[0], step = values[1];
    if (n < 1 || n > 256 || step < 1) return -1;
    return josephus_solve(n, step) + 1;
}
