/* Full-string wildcard matching for lowercase ASCII text. */
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

int64_t wildcard_matching(const int64_t *input, size_t length)
{
    if (input == NULL || length < 2 || length > 35) return -1;
    if (input[0] < 0 || input[0] > 12 || input[1] < 0 || input[1] > 20) return -1;
    const size_t text_length = (size_t)input[0];
    const size_t pattern_length = (size_t)input[1];
    if (length != 2 + text_length + pattern_length) return -1;
    for (size_t i = 0; i < text_length; ++i) {
        if (input[2 + i] < 97 || input[2 + i] > 122) return -1;
    }
    const size_t pattern_start = 2 + text_length;
    for (size_t j = 0; j < pattern_length; ++j) {
        const int64_t token = input[pattern_start + j];
        if (!((token >= 97 && token <= 122) || token == 42 || token == 63)) return -1;
    }
    bool dp[13][21] = {{false}};
    dp[0][0] = true;
    for (size_t j = 1; j <= pattern_length; ++j) {
        if (input[pattern_start + j - 1] == 42) dp[0][j] = dp[0][j - 1];
    }
    for (size_t i = 1; i <= text_length; ++i) {
        for (size_t j = 1; j <= pattern_length; ++j) {
            const int64_t token = input[pattern_start + j - 1];
            if (token == input[1 + i] || token == 63) dp[i][j] = dp[i - 1][j - 1];
            else if (token == 42) dp[i][j] = dp[i - 1][j] || dp[i][j - 1];
        }
    }
    return dp[text_length][pattern_length] ? 1 : 0;
}
