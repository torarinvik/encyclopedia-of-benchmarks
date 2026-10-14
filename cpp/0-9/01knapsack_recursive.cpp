#include <algorithm>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t MAX_CAPACITY = 512;
constexpr std::int64_t MAX_ITEMS = 16;
constexpr std::int64_t MAX_WEIGHT = 4096;
constexpr std::int64_t MAX_VALUE = 1'000'000'000;

std::int64_t solve(const std::int64_t *packed, std::int64_t item_count, std::int64_t capacity)
{
    if (item_count == 0 || capacity == 0) return 0;
    const std::size_t offset = 2 + 2 * static_cast<std::size_t>(item_count - 1);
    const std::int64_t weight = packed[offset];
    const std::int64_t value = packed[offset + 1];
    if (weight <= capacity) {
        const std::int64_t take = value + solve(packed, item_count - 1, capacity - weight);
        const std::int64_t skip = solve(packed, item_count - 1, capacity);
        return std::max(take, skip);
    }
    return solve(packed, item_count - 1, capacity);
}
}

extern "C" std::int64_t knapsack_01_recursive_benchmark(const std::int64_t *packed, std::size_t length)
{
    if (length < 2 || length > 2 + 2 * MAX_ITEMS) return -1;
    const std::int64_t capacity = packed[0];
    const std::int64_t item_count = packed[1];
    if (capacity < 0 || capacity > MAX_CAPACITY || item_count < 0 || item_count > MAX_ITEMS
        || length != 2 + 2 * static_cast<std::size_t>(item_count)) return -1;
    for (std::int64_t item = 0; item < item_count; ++item) {
        const std::size_t offset = 2 + 2 * static_cast<std::size_t>(item);
        if (packed[offset] < 1 || packed[offset] > MAX_WEIGHT
            || packed[offset + 1] < 0 || packed[offset + 1] > MAX_VALUE) return -1;
    }
    return solve(packed, item_count, capacity);
}
