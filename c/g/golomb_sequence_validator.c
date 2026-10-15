/* Check whether the packed values match the generated Golomb prefix. */
#include <stddef.h>
#include <stdint.h>

#define MAX_N 1024

int64_t golomb_sequence_validator(const int64_t *input, size_t length)
{
    if (input == NULL || length < 1 || length > MAX_N) return -1;
    if (input[0] < 1 || input[0] > MAX_N) return -1;
    const size_t n = (size_t)input[0];
    if (length != n) return -1;

    for (size_t index = 1; index < n; ++index)
        if (input[index] < INT32_MIN || input[index] > INT32_MAX) return -1;

    int64_t dp[MAX_N] = {0};
    dp[0] = 1;
    for (size_t i = 1; i < n; ++i) {
        const size_t previous = (size_t)dp[i - 1];
        const size_t nested = (size_t)dp[previous];
        const size_t source = i - nested;
        dp[i] = 1 + dp[source];
    }
    for (size_t index = 1; index < n; ++index)
        if (input[index] != dp[index]) return 0;
    return 1;
}
