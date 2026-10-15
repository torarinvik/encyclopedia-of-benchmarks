/* Independent portable implementation of TheAlgorithms/Java recursive search. */
#include <cstddef>
#include <cstdint>

static std::int64_t simple_binary_search_range(const std::int64_t *values,
                                                  std::size_t low,
                                                  std::size_t high,
                                                  std::int64_t target) noexcept
{
    if (low >= high) {
        return 0;
    }

    const std::size_t middle = low + (high - low) / 2;
    if (values[middle] == target) {
        return 1;
    }
    if (target < values[middle]) {
        return simple_binary_search_range(values, low, middle, target);
    }
    return simple_binary_search_range(values, middle + 1, high, target);
}

extern "C" std::int64_t simple_binary_search(const std::int64_t *values,
                                                 std::size_t length,
                                                 std::int64_t target) noexcept
{
    return simple_binary_search_range(values, 0, length, target);
}
