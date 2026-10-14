/*
 * Algorithm reference: TheAlgorithms/C-Plus-Plus search/binary_search.cpp
 * This portable implementation follows the local ascending-array contract and
 * was written independently of the upstream source.
 */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t binary_search(const std::int64_t *values,
                                      std::size_t length,
                                      std::int64_t target) noexcept
{
    std::size_t low = 0;
    std::size_t high = length;

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
