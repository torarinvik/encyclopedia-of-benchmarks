/* Independent portable implementation of TheAlgorithms/C++ bubble sort. */
#include <cstddef>
#include <cstdint>

extern "C" void bubble_sort(std::int64_t *values, std::size_t length) noexcept
{
    for (std::size_t end = length; end > 1; --end) {
        bool swapped = false;
        for (std::size_t index = 0; index + 1 < end; ++index) {
            if (values[index] > values[index + 1]) {
                const std::int64_t temporary = values[index];
                values[index] = values[index + 1];
                values[index + 1] = temporary;
                swapped = true;
            }
        }
        if (!swapped) break;
    }
}
