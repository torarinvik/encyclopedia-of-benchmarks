/* Independent portable implementation of TheAlgorithms/C++ insertion sort. */
#include <cstddef>
#include <cstdint>

extern "C" void insertion_sort(std::int64_t *values, std::size_t length) noexcept
{
    for (std::size_t index = 1; index < length; ++index) {
        const std::int64_t key = values[index];
        std::size_t position = index;
        while (position > 0 && values[position - 1] > key) {
            values[position] = values[position - 1];
            --position;
        }
        values[position] = key;
    }
}
