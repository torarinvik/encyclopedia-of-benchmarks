/*
 * Algorithm reference: TheAlgorithms/C-Plus-Plus search/exponential_search.cpp
 * This portable implementation follows the local contract independently.
 */
#include <cstddef>
#include <cstdint>

static std::int64_t binary_search_range(const std::int64_t *values, std::size_t low,
                                        std::size_t high, std::int64_t target) noexcept
{
    while (low < high) {
        const std::size_t middle = low + (high - low) / 2;
        const std::int64_t value = values[middle];
        if (value == target) {
            return static_cast<std::int64_t>(middle);
        }
        if (value < target) {
            low = middle + 1;
        } else {
            high = middle;
        }
    }

    return -1;
}

extern "C" std::int64_t exponential_search(const std::int64_t *values,
                                           std::size_t length,
                                           std::int64_t target) noexcept
{
    if (length == 0) {
        return -1;
    }

    std::size_t upper = 1;
    while (upper < length && values[upper] <= target) {
        upper = upper > length / 2 ? length : upper * 2;
    }

    return binary_search_range(values, upper / 2, upper, target);
}
