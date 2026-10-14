// Maximum profit from one buy followed by one sell.
#include <cstddef>
#include <cstdint>

extern "C" int64_t best_time_to_buy_and_sell_stock(const int64_t *prices, std::size_t length)
{
    if (length > 4096) return -1;
    if (length == 0) return 0;
    int64_t minimum = prices[0];
    int64_t best = 0;
    for (std::size_t day = 0; day < length; ++day) {
        const int64_t price = prices[day];
        if (price < 0 || price > 1000000000) return -1;
        if (price < minimum) minimum = price;
        const int64_t profit = price - minimum;
        if (profit > best) best = profit;
    }
    return best;
}
