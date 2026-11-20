/* Clean-room iterative unwinding of OI Wiki's batched Josephus recurrence. */
#include <stddef.h>
#include <stdint.h>

#define JOSEPHUS_MAX_FRAMES 1024

int64_t josephus_batched_small_k(const int64_t *values, size_t length) {
    if (values == NULL || length != 2) return -1;
    const int64_t n0 = values[0], k = values[1];
    if (n0 < 1 || n0 > 1000000 || k < 1 || k > 32) return -1;
    if (n0 == 1) return 0;
    if (k == 1) return n0 - 1;

    int64_t frames[JOSEPHUS_MAX_FRAMES];
    size_t depth = 0;
    int64_t n = n0;
    while (n > 1) {
        if (depth == JOSEPHUS_MAX_FRAMES) return -1;
        frames[depth++] = n;
        n = n < k ? n - 1 : n - n / k;
    }
    int64_t survivor = 0;
    while (depth > 0) {
        const int64_t m = frames[--depth];
        if (m < k) {
            survivor = (survivor + k) % m;
        } else {
            survivor -= m % k;
            if (survivor < 0) survivor += m;
            else survivor += survivor / (k - 1);
        }
    }
    return survivor;
}
