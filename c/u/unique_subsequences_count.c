#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 30

int64_t unique_subsequences_count(const int64_t *input, size_t length) {
    if (input == NULL || length < 1 || length > MAX_LENGTH + 1) return -1;
    if (input[0] < 0 || input[0] > MAX_LENGTH || length != (size_t)input[0] + 1) return -1;
    size_t n = (size_t)input[0];
    for (size_t i = 0; i < n; ++i) if (input[i + 1] < 0 || input[i + 1] > 127) return -1;
    int64_t dp[MAX_LENGTH + 1] = {0};
    for (size_t end = n; end > 0; --end) {
        size_t i = end - 1;
        uint8_t seen[128] = {0};
        for (size_t j = i; j < n; ++j) {
            size_t ch = (size_t)input[j + 1];
            if (seen[ch]) continue;
            seen[ch] = 1;
            dp[i] += 1 + dp[j + 1];
        }
    }
    return dp[0];
}
