/* Bottom-up count of ordered denomination sequences. */
#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT (INT64_MIN)

int64_t combination_sum_iv(const int64_t *packed, size_t length)
{
    if (packed == NULL || length < 2 || length > 18) return INVALID_RESULT;
    if (packed[0] < 0 || packed[0] > 16 || packed[1] < 0 || packed[1] > 63) return INVALID_RESULT;
    const size_t count = (size_t)packed[0];
    const size_t target = (size_t)packed[1];
    if (length != count + 2) return INVALID_RESULT;
    for (size_t i = 0; i < count; ++i) {
        if (packed[i + 2] < 1 || packed[i + 2] > 63) return INVALID_RESULT;
        for (size_t j = 0; j < i; ++j) {
            if (packed[i + 2] == packed[j + 2]) return INVALID_RESULT;
        }
    }

    int64_t dp[64] = {0};
    dp[0] = 1;
    for (size_t sum = 1; sum <= target; ++sum) {
        for (size_t i = 0; i < count; ++i) {
            const size_t denomination = (size_t)packed[i + 2];
            if (denomination <= sum) dp[sum] += dp[sum - denomination];
        }
    }
    return dp[target];
}
