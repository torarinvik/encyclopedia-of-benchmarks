/*
 * Algorithm reference: TheAlgorithms/C-Plus-Plus search/linear_search.cpp
 * This portable implementation follows the local benchmark contract and was
 * written independently of the upstream source.
 */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t linear_search(const std::int64_t *values,
                                      std::size_t length,
                                      std::int64_t target) noexcept
{
    for (std::size_t index = 0; index < length; ++index) {
        if (values[index] == target) {
            return static_cast<std::int64_t>(index);
        }
    }

    return -1;
}
