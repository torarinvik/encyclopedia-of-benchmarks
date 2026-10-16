#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_ITEMS = 14;
constexpr std::int64_t MAX_PRICE = 1000000;

std::int64_t solve(const std::int64_t *prices, std::size_t count,
                   std::size_t first, std::size_t last) {
    const auto year = static_cast<std::int64_t>(count - (last - first + 1) + 1);
    if (first == last) return prices[first] * year;
    const auto sell_first = prices[first] * year + solve(prices, count, first + 1, last);
    const auto sell_last = prices[last] * year + solve(prices, count, first, last - 1);
    return sell_first > sell_last ? sell_first : sell_last;
}
} // namespace

extern "C" std::int64_t wine_problem_recursive(const std::int64_t *prices, std::size_t length) {
    if (prices == nullptr || length == 0 || length > MAX_ITEMS) return -1;
    for (std::size_t index = 0; index < length; ++index)
        if (prices[index] < 0 || prices[index] > MAX_PRICE) return -1;
    return solve(prices, length, 0, length - 1);
}
