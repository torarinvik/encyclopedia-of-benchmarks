#include <stddef.h>
#include <stdint.h>

#define MAX_BALLOONS 128

int64_t burstballoons(const int64_t *values, size_t length) {
    if (length > MAX_BALLOONS || (length != 0 && values == NULL)) {
        return -1;
    }
    for (size_t index = 0; index < length; ++index) {
        if (values[index] < 0 || values[index] > 1000) {
            return -1;
        }
    }
    if (length == 0) {
        return 0;
    }

    int64_t padded[MAX_BALLOONS + 2] = {0};
    int64_t dp[MAX_BALLOONS + 2][MAX_BALLOONS + 2] = {{0}};
    padded[0] = 1;
    padded[length + 1] = 1;
    for (size_t index = 0; index < length; ++index) {
        padded[index + 1] = values[index];
    }

    for (size_t span = 1; span <= length; ++span) {
        for (size_t left = 1; left + span - 1 <= length; ++left) {
            const size_t right = left + span - 1;
            int64_t best = 0;
            for (size_t last = left; last <= right; ++last) {
                const int64_t coins = dp[left][last - 1] + dp[last + 1][right]
                    + padded[left - 1] * padded[last] * padded[right + 1];
                if (coins > best) {
                    best = coins;
                }
            }
            dp[left][right] = best;
        }
    }
    return dp[1][length];
}
