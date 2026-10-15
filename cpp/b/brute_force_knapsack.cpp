#include <algorithm>
#include <cstddef>
#include <cstdint>

namespace {
std::int64_t solve(const std::int64_t *packed, std::size_t item_count, std::int64_t capacity)
{
    if (item_count == 0 || capacity == 0) return 0;
    const auto weight = packed[2 + 2 * (item_count - 1)];
    const auto value = packed[3 + 2 * (item_count - 1)];
    if (weight > capacity) return solve(packed, item_count - 1, capacity);
    const auto excluded = solve(packed, item_count - 1, capacity);
    const auto included = value + solve(packed, item_count - 1, capacity - weight);
    return std::max(excluded, included);
}
}

extern "C" std::int64_t brute_force_knapsack(const std::int64_t *packed, std::size_t length) noexcept
{
    if (packed == nullptr || length < 2 || length > 30) return -1;
    const auto capacity = packed[0];
    const auto count_value = packed[1];
    if (capacity < 0 || capacity > 512 || count_value < 0 || count_value > 14) return -1;
    const auto item_count = static_cast<std::size_t>(count_value);
    if (length != 2 + 2 * item_count) return -1;
    for (std::size_t item = 0; item < item_count; ++item) {
        const auto weight = packed[2 + 2 * item];
        const auto value = packed[3 + 2 * item];
        if (weight < 1 || weight > 4096 || value < 0 || value > 100000000) return -1;
    }
    return solve(packed, item_count, capacity);
}
