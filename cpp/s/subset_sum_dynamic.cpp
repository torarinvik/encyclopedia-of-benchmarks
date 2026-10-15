/* Memoized top-down subset existence for signed values. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxItems = 16;
constexpr std::size_t kWidth = 801;
constexpr std::size_t kStates = (kMaxItems + 1) * kWidth;
std::int64_t search(const std::int64_t *input, std::size_t item_count,
                    std::size_t index, std::int64_t remaining,
                    std::int64_t *memo) noexcept {
    if (remaining == 0) return 1;
    if (index == item_count) return 0;
    const auto state = index * kWidth + static_cast<std::size_t>(remaining + 400);
    if (memo[state] != -2) return memo[state];
    auto result = search(input, item_count, index + 1,
                         remaining - input[index + 1], memo);
    if (result == 0) result = search(input, item_count, index + 1, remaining, memo);
    memo[state] = result;
    return result;
}
}

extern "C" std::int64_t subset_sum_dynamic(const std::int64_t *input,
                                             std::size_t length) noexcept {
    if (input == nullptr || length == 0 || length > kMaxItems + 1) return -1;
    const auto target = input[0];
    if (target < -80 || target > 80) return -1;
    for (std::size_t i = 1; i < length; ++i)
        if (input[i] < -20 || input[i] > 20) return -1;
    std::int64_t memo[kStates];
    for (auto &entry : memo) entry = -2;
    return search(input, length - 1, 0, target, memo);
}
