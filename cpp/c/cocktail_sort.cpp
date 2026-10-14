/* Stable bidirectional bubble sort for signed 64-bit values. */
#include <cstddef>
#include <cstdint>

extern "C" void cocktail_sort(std::int64_t *values, std::size_t length) noexcept
{
    std::size_t start = 0;
    std::size_t end = length;
    while (start < end) {
        bool swapped = false;
        for (std::size_t index = start; index + 1 < end; ++index) {
            if (values[index] > values[index + 1]) {
                const std::int64_t temporary = values[index];
                values[index] = values[index + 1];
                values[index + 1] = temporary;
                swapped = true;
            }
        }
        if (!swapped) break;
        --end;
        swapped = false;
        std::size_t index = end;
        while (index > start) {
            if (values[index - 1] > values[index]) {
                const std::int64_t temporary = values[index - 1];
                values[index - 1] = values[index];
                values[index] = temporary;
                swapped = true;
            }
            --index;
        }
        ++start;
        if (!swapped) break;
    }
}
