/* Count unordered partitions of a positive integer using the pinned 2D DP. */
#include <stdint.h>

#define MAX_N 300
#define STRIDE MAX_N

int64_t integer_partition(int64_t m)
{
    if (m < 1 || m > MAX_N) return INT64_MIN;

    int64_t memo[(MAX_N + 1) * STRIDE] = {0};
    for (int64_t i = 0; i <= m; ++i) memo[i * STRIDE] = 1;
    for (int64_t n = 0; n <= m; ++n) {
        for (int64_t k = 1; k < m; ++k) {
            memo[n * STRIDE + k] += memo[n * STRIDE + k - 1];
            if (n - k > 0) memo[n * STRIDE + k] += memo[(n - k - 1) * STRIDE + k];
        }
    }
    return memo[m * STRIDE + m - 1];
}
