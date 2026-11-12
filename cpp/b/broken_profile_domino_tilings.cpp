#include <array>
#include <algorithm>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kStates = 256;
constexpr std::int64_t kMod = 998244353;
}

extern "C" std::int64_t broken_profile_domino_tilings(const std::int64_t *input, std::size_t length) {
    if (input == nullptr || length != 2) return -1;
    const auto h0 = input[0], w0 = input[1];
    if (h0 < 1 || h0 > 64 || w0 < 1 || w0 > 64 || std::min(h0, w0) > 8 || h0 * w0 > 512) return -1;
    const auto height = static_cast<std::size_t>(std::max(h0, w0));
    const auto width = static_cast<std::size_t>(std::min(h0, w0));
    const auto states = std::size_t{1} << width, full = states - 1;
    std::array<std::int64_t, kStates> dp{}, next{}; dp[0] = 1;
    for (std::size_t row = 0; row < height; ++row) {
        next.fill(0);
        for (std::size_t in = 0; in < states; ++in) if (dp[in]) {
            for (std::size_t out = 0; out < states; ++out) {
                if ((in & out) || (row + 1 == height && out != 0)) continue;
                const auto free = full & ~(in | out); std::size_t col = 0; bool valid = true;
                while (col < width) {
                    if ((free >> col) & 1u) {
                        if (col + 1 >= width || ((free >> (col + 1)) & 1u) == 0) { valid = false; break; }
                        col += 2;
                    } else ++col;
                }
                if (valid) next[out] = (next[out] + dp[in]) % kMod;
            }
        }
        dp = next;
    }
    return dp[0];
}
