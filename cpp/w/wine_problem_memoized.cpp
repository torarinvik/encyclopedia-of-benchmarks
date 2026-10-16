#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_ITEMS = 64;
constexpr std::int64_t MAX_PRICE = 1000000;

std::int64_t solve(const std::int64_t *prices, std::size_t count,
                   std::size_t first, std::size_t last, std::int64_t *memo) {
    const auto slot = first * MAX_ITEMS + last;
    const auto year = static_cast<std::int64_t>(count - (last - first + 1) + 1);
    if (first == last) { memo[slot] = prices[first] * year; return memo[slot]; }
    if (memo[slot] != 0) return memo[slot];
    const auto sell_first = prices[first] * year + solve(prices, count, first + 1, last, memo);
    const auto sell_last = prices[last] * year + solve(prices, count, first, last - 1, memo);
    memo[slot] = sell_first > sell_last ? sell_first : sell_last;
    return memo[slot];
}
} // namespace

extern "C" std::int64_t wine_problem_memoized(const std::int64_t *prices, std::size_t length) {
    if (prices == nullptr || length == 0 || length > MAX_ITEMS) return -1;
    for (std::size_t index = 0; index < length; ++index)
        if (prices[index] < 1 || prices[index] > MAX_PRICE) return -1;
    std::int64_t memo[MAX_ITEMS * MAX_ITEMS] = {};
    return solve(prices, length, 0, length - 1, memo);
}
