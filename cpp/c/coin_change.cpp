/* Return the minimum number of unlimited coins needed to reach an amount. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t coin_change(const std::int64_t *packed, std::size_t length) noexcept
{
    if (packed == nullptr || length < 2 || length > 130) return -1;
    const std::int64_t amount = packed[0];
    const std::int64_t coin_count = packed[1];
    if (amount < 0 || amount > 512 || coin_count < 0 || coin_count > 128 ||
        length != static_cast<std::size_t>(2 + coin_count)) return -1;
    for (std::size_t coin_index = 0; coin_index < static_cast<std::size_t>(coin_count); ++coin_index) {
        if (packed[2 + coin_index] < 1 || packed[2 + coin_index] > 4096) return -1;
    }

    std::int64_t minimum[513]{};
    for (std::size_t current = 1; current <= static_cast<std::size_t>(amount); ++current) {
        std::int64_t best = 513;
        for (std::size_t coin_index = 0; coin_index < static_cast<std::size_t>(coin_count); ++coin_index) {
            const std::size_t coin = static_cast<std::size_t>(packed[2 + coin_index]);
            if (coin <= current && minimum[current - coin] < 513 &&
                minimum[current - coin] + 1 < best) {
                best = minimum[current - coin] + 1;
            }
        }
        minimum[current] = best;
    }
    return minimum[static_cast<std::size_t>(amount)] < 513
        ? minimum[static_cast<std::size_t>(amount)] : -1;
}
