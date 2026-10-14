/* Return the LCS length of two packed ASCII sequences. */
#include <stddef.h>
#include <stdint.h>

int64_t longest_common_subsequence(const int64_t *packed, size_t length)
{
    if (packed == NULL || length < 2 || length > 512) return -1;
    const int64_t left_length = packed[0];
    const int64_t right_length = packed[1];
    if (left_length < 0 || left_length > 255 || right_length < 0 || right_length > 255 ||
        length != (size_t)(2 + left_length + right_length)) return -1;
    for (size_t index = 0; index < (size_t)(left_length + right_length); ++index) {
        if (packed[2 + index] < 0 || packed[2 + index] > 127) return -1;
    }

    int64_t dp[256] = {0};
    for (size_t left = 0; left < (size_t)left_length; ++left) {
        int64_t diagonal = 0;
        for (size_t right = 1; right <= (size_t)right_length; ++right) {
            const int64_t above = dp[right];
            if (packed[2 + left] == packed[2 + (size_t)left_length + right - 1]) {
                dp[right] = diagonal + 1;
            } else if (dp[right - 1] > dp[right]) {
                dp[right] = dp[right - 1];
            }
            diagonal = above;
        }
    }
    return dp[(size_t)right_length];
}
