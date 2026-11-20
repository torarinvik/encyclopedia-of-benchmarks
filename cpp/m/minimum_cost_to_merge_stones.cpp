#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <limits>

namespace {
constexpr std::size_t kMaxN = 30;
constexpr std::size_t kMaxK = 30;
constexpr std::size_t kDpCells = kMaxN * kMaxN * (kMaxK + 1);
constexpr std::int64_t kInfinity = std::numeric_limits<std::int64_t>::max() / 4;

constexpr std::size_t dp_index(std::size_t left, std::size_t right, std::size_t piles) noexcept {
    return (left * kMaxN + right) * (kMaxK + 1) + piles;
}
}

extern "C" std::int64_t minimum_cost_to_merge_stones(const std::int64_t *input,
                                                      std::size_t length) noexcept {
    if (input == nullptr || length < 3 || length > 33) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(kMaxN) ||
        input[1] < 2 || input[1] > static_cast<std::int64_t>(kMaxK)) return -1;
    const std::size_t n = static_cast<std::size_t>(input[0]);
    const std::size_t merge_count = static_cast<std::size_t>(input[1]);
    if (length != n + 2) return -1;

    std::int64_t prefix[kMaxN + 1]{};
    for (std::size_t i = 0; i < n; ++i) {
        const std::int64_t stone = input[i + 2];
        if (stone < 1 || stone > 100) return -1;
        prefix[i + 1] = prefix[i] + stone;
    }
    if ((n - 1) % (merge_count - 1) != 0) return -1;

    std::int64_t dp[kDpCells];
    std::fill_n(dp, kDpCells, kInfinity);
    for (std::size_t i = 0; i < n; ++i) dp[dp_index(i, i, 1)] = 0;
    for (std::size_t interval_length = 2; interval_length <= n; ++interval_length) {
        for (std::size_t left = 0; left + interval_length <= n; ++left) {
            const std::size_t right = left + interval_length - 1;
            const std::size_t maximum_piles = std::min(merge_count, interval_length);
            for (std::size_t piles = 2; piles <= maximum_piles; ++piles) {
                std::int64_t best = kInfinity;
                for (std::size_t cut = left; cut < right; ++cut) {
                    const auto first = dp[dp_index(left, cut, 1)];
                    const auto rest = dp[dp_index(cut + 1, right, piles - 1)];
                    if (first < kInfinity && rest < kInfinity) best = std::min(best, first + rest);
                }
                dp[dp_index(left, right, piles)] = best;
            }
            if (interval_length >= merge_count) {
                const auto to_k = dp[dp_index(left, right, merge_count)];
                if (to_k < kInfinity) dp[dp_index(left, right, 1)] = to_k + prefix[right + 1] - prefix[left];
            }
        }
    }
    const auto answer = dp[dp_index(0, n - 1, 1)];
    return answer >= kInfinity ? -1 : answer;
}
