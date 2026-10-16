#include <cstdint>

namespace {
constexpr std::int64_t MAX_TARGET = 500;
}

extern "C" std::int64_t problem31(std::int64_t target) noexcept
{
    if (target < 0 || target > MAX_TARGET) return -1;
    constexpr std::int64_t coins[] = {1, 2, 5, 10, 20, 50, 100, 200};
    std::int64_t ways[MAX_TARGET + 1]{};
    ways[0] = 1;
    for (const std::int64_t coin : coins) {
        for (std::int64_t amount = coin; amount <= target; ++amount) {
            ways[amount] += ways[amount - coin];
        }
    }
    return ways[target];
}
