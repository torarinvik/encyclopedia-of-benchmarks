#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH INT64_C(8)
#define MAX_SYMBOL INT64_C(2)
#define TABLE_SIDE 9

int64_t strange_printer(const int64_t *input, size_t length) {
    if (input == NULL || length < 1 || length > 10) return -1;
    const int64_t n_raw = input[0];
    if (n_raw < 0 || n_raw > MAX_LENGTH || length != (size_t)n_raw + 1) return -1;
    const size_t n = (size_t)n_raw;
    for (size_t position = 0; position < n; ++position) {
        if (input[position + 1] < 0 || input[position + 1] > MAX_SYMBOL) return -1;
    }
    if (n == 0) return 0;

    int64_t dp[TABLE_SIDE * TABLE_SIDE] = {0};
    for (size_t left = n; left-- > 0;) {
        dp[left * TABLE_SIDE + left] = 1;
        for (size_t right = left + 1; right < n; ++right) {
            int64_t best = dp[(left + 1) * TABLE_SIDE + right] + 1;
            for (size_t merge = left + 1; merge <= right; ++merge) {
                if (input[left + 1] != input[merge + 1]) continue;
                const int64_t middle = merge == left + 1
                    ? 0 : dp[(left + 1) * TABLE_SIDE + merge - 1];
                const int64_t candidate = middle + dp[merge * TABLE_SIDE + right];
                if (candidate < best) best = candidate;
            }
            dp[left * TABLE_SIDE + right] = best;
        }
    }
    return dp[n - 1];
}
