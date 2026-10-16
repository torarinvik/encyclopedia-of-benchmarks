#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_amount = 30;
constexpr std::size_t max_coins = 8;
}

extern "C" std::int64_t coinchange(const std::int64_t *values, std::size_t length) {
    if (values == nullptr || length < 2 || length > max_coins + 2) {
        return -1;
    }
    const std::int64_t amount_value = values[0];
    const std::int64_t coin_count_value = values[1];
    if (amount_value < 1 || amount_value > static_cast<std::int64_t>(max_amount) ||
        coin_count_value < 0 || coin_count_value > static_cast<std::int64_t>(max_coins)) {
        return -1;
    }
    const auto amount = static_cast<std::size_t>(amount_value);
    const auto coin_count = static_cast<std::size_t>(coin_count_value);
    if (length != coin_count + 2) {
        return -1;
    }
    for (std::size_t index = 0; index < coin_count; ++index) {
        if (values[index + 2] < 1 || values[index + 2] > static_cast<std::int64_t>(max_amount)) {
            return -1;
        }
    }

    std::int64_t combinations[max_amount]{};
    combinations[0] = 1;
    for (std::size_t coin_index = 0; coin_index < coin_count; ++coin_index) {
        const auto coin = static_cast<std::size_t>(values[coin_index + 2]);
        for (std::size_t subtotal = coin; subtotal < amount; ++subtotal) {
            combinations[subtotal] += combinations[subtotal - coin];
        }
    }
    return combinations[amount - 1];
}
