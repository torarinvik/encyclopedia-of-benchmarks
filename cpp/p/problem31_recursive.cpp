#include <cstdint>

namespace {
constexpr std::int64_t MAX_TARGET = 200;
constexpr std::int64_t COINS[] = {1, 2, 5, 10, 20, 50, 100, 200};

std::int64_t count_ways(std::int64_t target, int coin_index) noexcept
{
    if (target < 0) return 0;
    if (coin_index == 0) return 1;
    const std::int64_t coin = COINS[coin_index];
    return count_ways(target - coin, coin_index) + count_ways(target, coin_index - 1);
}
}

extern "C" std::int64_t problem31_recursive(std::int64_t target) noexcept
{
    if (target < 0 || target > MAX_TARGET) return -1;
    return count_ways(target, 7);
}
