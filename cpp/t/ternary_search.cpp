/* Independent portable implementation of TheAlgorithms/C-Plus-Plus ternary search. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t ternary_search(const std::int64_t *values,
                                       std::size_t length,
                                       std::int64_t target) noexcept
{
    std::size_t low = 0;
    std::size_t high = length;
    while (low < high) {
        const std::size_t third = (high - low) / 3;
        const std::size_t first = low + third;
        const std::size_t second = high - third - 1;
        const std::int64_t first_value = values[first];
        const std::int64_t second_value = values[second];
        if (first_value == target) return static_cast<std::int64_t>(first);
        if (second_value == target) return static_cast<std::int64_t>(second);
        if (target < first_value) {
            high = first;
        } else if (target > second_value) {
            low = second + 1;
        } else {
            low = first + 1;
            high = second;
        }
    }
    return -1;
}
