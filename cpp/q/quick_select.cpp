/* Return the upper median using three-way quickselect on a local copy. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_values = 1024;

std::int64_t median_of_three(std::int64_t first, std::int64_t middle, std::int64_t last) noexcept
{
    if (first < middle) {
        if (middle < last) return middle;
        return first < last ? last : first;
    }
    if (first < last) return first;
    return middle < last ? last : middle;
}
}

extern "C" std::int64_t quick_select(const std::int64_t *values, std::size_t length) noexcept
{
    if (length == 0 || length > max_values) return -1;
    std::int64_t scratch[max_values];
    for (std::size_t index = 0; index < length; ++index) scratch[index] = values[index];

    const std::size_t target = length / 2;
    std::size_t low = 0;
    std::size_t high = length;
    while (high - low > 1) {
        const std::size_t middle = low + (high - low) / 2;
        const std::int64_t pivot = median_of_three(scratch[low], scratch[middle], scratch[high - 1]);
        std::size_t less = low;
        std::size_t scan = low;
        std::size_t greater = high;
        while (scan < greater) {
            if (scratch[scan] < pivot) {
                const std::int64_t temporary = scratch[less];
                scratch[less++] = scratch[scan];
                scratch[scan++] = temporary;
            } else if (scratch[scan] > pivot) {
                const std::int64_t temporary = scratch[--greater];
                scratch[greater] = scratch[scan];
                scratch[scan] = temporary;
            } else {
                ++scan;
            }
        }
        if (target < less) high = less;
        else if (target >= greater) low = greater;
        else return pivot;
    }
    return scratch[target];
}
