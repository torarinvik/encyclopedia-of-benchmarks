#include <cstddef>
#include <cstdint>

extern "C" std::int64_t wine_problem_tabulated(const std::int64_t *prices, std::size_t length) {
    constexpr std::size_t MAX_ITEMS = 64;
    constexpr std::int64_t MAX_PRICE = 1000000;
    if (prices == nullptr || length == 0 || length > MAX_ITEMS) return -1;
    for (std::size_t index = 0; index < length; ++index)
        if (prices[index] < 0 || prices[index] > MAX_PRICE) return -1;
    std::int64_t table[MAX_ITEMS * MAX_ITEMS] = {};
    for (std::size_t width = 1; width <= length; ++width) {
        const auto year = static_cast<std::int64_t>(length - width + 1);
        for (std::size_t first = 0; first + width <= length; ++first) {
            const auto last = first + width - 1;
            const auto slot = first * MAX_ITEMS + last;
            if (first == last) {
                table[slot] = prices[first] * year;
            } else {
                const auto sell_first = prices[first] * year + table[(first + 1) * MAX_ITEMS + last];
                const auto sell_last = prices[last] * year + table[first * MAX_ITEMS + last - 1];
                table[slot] = sell_first > sell_last ? sell_first : sell_last;
            }
        }
    }
    return table[length - 1];
}
