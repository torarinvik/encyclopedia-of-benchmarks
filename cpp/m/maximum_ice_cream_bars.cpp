#include <cstddef>
#include <cstdint>

extern "C" std::int64_t maximum_ice_cream_bars(const std::int64_t *input, std::size_t length) {
    if (length < 1 || length > 257 || input == nullptr) return -1;
    const std::int64_t coins = input[0];
    const std::size_t count = length - 1;
    if (coins < 0 || coins > 1000000) return -1;
    std::int64_t costs[256];
    for (std::size_t index = 0; index < count; ++index) {
        const std::int64_t cost = input[index + 1];
        if (cost < 1 || cost > 10000) return -1;
        std::size_t position = index;
        while (position > 0 && costs[position - 1] > cost) {
            costs[position] = costs[position - 1];
            --position;
        }
        costs[position] = cost;
    }
    std::int64_t remaining = coins;
    std::int64_t bought = 0;
    for (std::size_t index = 0; index < count; ++index) {
        if (costs[index] > remaining) break;
        remaining -= costs[index];
        ++bought;
    }
    return bought;
}
