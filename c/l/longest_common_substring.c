#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 256

int64_t longest_common_substring(const int64_t *input, size_t length)
{
    if (input == NULL || length < 2 || input[0] < 0 || input[0] > MAX_LENGTH) return -1;
    const size_t first_length = (size_t)input[0];
    if (first_length + 2 > length || input[first_length + 1] < 0 || input[first_length + 1] > MAX_LENGTH) return -1;
    const size_t second_length = (size_t)input[first_length + 1];
    if (length != first_length + second_length + 2) return -1;
    const int64_t *first = input + 1, *second = input + first_length + 2;
    for (size_t i = 0; i < first_length; ++i) if (first[i] < 32 || first[i] > 126) return -1;
    for (size_t i = 0; i < second_length; ++i) if (second[i] < 32 || second[i] > 126) return -1;
    int64_t dp[MAX_LENGTH + 1] = {0};
    int64_t best = 0;
    for (size_t i = 1; i <= first_length; ++i) {
        for (size_t j = second_length; j > 0; --j) {
            if (first[i - 1] == second[j - 1]) {
                dp[j] = dp[j - 1] + 1;
                if (dp[j] > best) best = dp[j];
            } else dp[j] = 0;
        }
    }
    return best;
}
