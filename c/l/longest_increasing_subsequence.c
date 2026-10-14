/* Return the length of a strictly increasing subsequence. */
#include <stddef.h>
#include <stdint.h>

int64_t longest_increasing_subsequence(const int64_t *values, size_t length)
{
    if (length > 512 || (length != 0 && values == NULL)) return -1;
    int64_t dp[512];
    int64_t longest = 0;
    for (size_t index = 0; index < length; ++index) {
        dp[index] = 1;
        for (size_t previous = 0; previous < index; ++previous) {
            if (values[index] > values[previous] && dp[index] < dp[previous] + 1)
                dp[index] = dp[previous] + 1;
        }
        if (dp[index] > longest) longest = dp[index];
    }
    return longest;
}
