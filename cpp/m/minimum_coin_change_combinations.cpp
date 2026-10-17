#include <cstddef>
#include <cstdint>

extern "C" std::int64_t minimum_coin_change_combinations(const std::int64_t *values,
                                                          std::size_t length) noexcept
{
    if (values == nullptr || length < 2 || length > 34) return -1;

    const std::int64_t target = values[0];
    const std::int64_t count_value = values[1];
    if (target < -64 || target > 64 || count_value < 0 || count_value > 32) return -1;
    const std::size_t count = static_cast<std::size_t>(count_value);
    if (length != count + 2) return -1;

    std::int64_t previous = 0;
    for (std::size_t index = 0; index < count; ++index) {
        const std::int64_t coin = values[index + 2];
        if (coin < 1 || coin > 64 || coin <= previous) return -1;
        previous = coin;
    }

    if (target < 0) return 0;
    std::int64_t ways[65] = {};
    ways[0] = 1;
    for (std::size_t index = 0; index < count; ++index) {
        const std::size_t coin = static_cast<std::size_t>(values[index + 2]);
        for (std::size_t amount = coin; amount <= static_cast<std::size_t>(target); ++amount) {
            ways[amount] += ways[amount - coin];
        }
    }
    return ways[static_cast<std::size_t>(target)];
}
