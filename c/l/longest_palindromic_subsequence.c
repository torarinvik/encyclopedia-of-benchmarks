/* Return the longest palindromic subsequence length using interval DP. */
#include <stddef.h>
#include <stdint.h>

#define MAX_VALUES 128
int64_t longest_palindromic_subsequence(const int64_t *values, size_t length)
{
    if (length > MAX_VALUES) return -1;
    if (length == 0) return 0;
    int64_t dp[MAX_VALUES] = {0};
    for (size_t start = length; start > 0;) {
        --start;
        dp[start] = 1;
        int64_t diagonal = 0;
        for (size_t end = start + 1; end < length; ++end) {
            const int64_t previous = dp[end];
            if (values[start] == values[end]) {
                dp[end] = diagonal + 2;
            } else {
                dp[end] = dp[end] > dp[end - 1] ? dp[end] : dp[end - 1];
            }
            diagonal = previous;
        }
    }
    return dp[length - 1];
}
