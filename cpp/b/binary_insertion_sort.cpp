/* Stable binary insertion sort for signed 64-bit values. */
#include <cstddef>
#include <cstdint>

extern "C" void binary_insertion_sort(std::int64_t *values, std::size_t length) noexcept
{
    for (std::size_t index = 1; index < length; ++index) {
        const std::int64_t key = values[index];
        std::size_t low = 0;
        std::size_t high = index;
        while (low < high) {
            const std::size_t middle = low + (high - low) / 2;
            if (values[middle] <= key) low = middle + 1;
            else high = middle;
        }
        std::size_t position = index;
        while (position > low) {
            values[position] = values[position - 1];
            --position;
        }
        values[low] = key;
    }
}
