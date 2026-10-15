/* Binary search over a monotone sequence in either direction. */
#include <cstddef>
#include <cstdint>
#include <limits>

extern "C" std::int64_t order_agnostic_binary_search(const std::int64_t *values,
                                                      std::size_t length) noexcept
{
    constexpr std::int64_t max_items = 99999;
    if (values == nullptr || length < 3 || length > 100001) return -1;
    const std::int64_t target = values[0], count = values[1];
    if (target < std::numeric_limits<std::int32_t>::min() ||
        target > std::numeric_limits<std::int32_t>::max() || count < 1 || count > max_items ||
        length != static_cast<std::size_t>(count) + 2) return -1;
    const bool ascending = values[2] < values[static_cast<std::size_t>(count) + 1];
    std::int64_t start = 0, end = count - 1;
    while (start <= end) {
        const std::int64_t middle = start + (end - start) / 2;
        const std::int64_t value = values[static_cast<std::size_t>(middle) + 2];
        if (value == target) return middle;
        if (ascending) {
            if (value < target) start = middle + 1;
            else end = middle - 1;
        } else {
            if (value > target) start = middle + 1;
            else end = middle - 1;
        }
    }
    return -1;
}
