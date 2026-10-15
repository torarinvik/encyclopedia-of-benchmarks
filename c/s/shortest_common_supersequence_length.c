/* Return shortest common supersequence length for two packed ASCII sequences. */
#include <stddef.h>
#include <stdint.h>

int64_t shortest_common_supersequence_length(const int64_t *packed, size_t length)
{
    if (packed == NULL || length < 2 || length > 512) return -1;
    const int64_t m = packed[0], n = packed[1];
    if (m < 0 || m > 255 || n < 0 || n > 255 || length != (size_t)(2 + m + n)) return -1;
    for (size_t k = 0; k < (size_t)(m + n); ++k)
        if (packed[2 + k] < 0 || packed[2 + k] > 127) return -1;

    const size_t columns = (size_t)n + 1;
    int64_t dp[256 * 256] = {0};
    for (size_t i = 1; i <= (size_t)m; ++i) {
        for (size_t j = 1; j <= (size_t)n; ++j) {
            const size_t cell = i * columns + j;
            if (packed[1 + i] == packed[1 + (size_t)m + j])
                dp[cell] = dp[(i - 1) * columns + j - 1] + 1;
            else {
                const int64_t above = dp[(i - 1) * columns + j];
                const int64_t left = dp[i * columns + j - 1];
                dp[cell] = above > left ? above : left;
            }
        }
    }
    return m + n - dp[(size_t)m * columns + (size_t)n];
}
