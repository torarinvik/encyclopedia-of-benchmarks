#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_balloons = 128;
}

extern "C" std::int64_t burstballoons(const std::int64_t *values, std::size_t length) {
    if (length > max_balloons || (length != 0 && values == nullptr)) {
        return -1;
    }
    for (std::size_t index = 0; index < length; ++index) {
        if (values[index] < 0 || values[index] > 1000) {
            return -1;
        }
    }
    if (length == 0) {
        return 0;
    }

    std::int64_t padded[max_balloons + 2]{};
    std::int64_t dp[max_balloons + 2][max_balloons + 2]{};
    padded[0] = 1;
    padded[length + 1] = 1;
    for (std::size_t index = 0; index < length; ++index) {
        padded[index + 1] = values[index];
    }

    for (std::size_t span = 1; span <= length; ++span) {
        for (std::size_t left = 1; left + span - 1 <= length; ++left) {
            const std::size_t right = left + span - 1;
            std::int64_t best = 0;
            for (std::size_t last = left; last <= right; ++last) {
                const std::int64_t coins = dp[left][last - 1] + dp[last + 1][right]
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
