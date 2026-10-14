/* Independent portable implementation of TheAlgorithms/C++ odd-even sort. */
#include <cstddef>
#include <cstdint>

extern "C" void odd_even_sort(std::int64_t *values, std::size_t length) noexcept
{
    if (length < 2) return;
    bool swapped = true;
    while (swapped) {
        swapped = false;
        for (std::size_t index = 0; index + 1 < length; index += 2) {
            if (values[index] > values[index + 1]) {
                const std::int64_t temporary = values[index];
                values[index] = values[index + 1];
                values[index + 1] = temporary;
                swapped = true;
            }
        }
        for (std::size_t index = 1; index + 1 < length; index += 2) {
            if (values[index] > values[index + 1]) {
                const std::int64_t temporary = values[index];
                values[index] = values[index + 1];
                values[index + 1] = temporary;
                swapped = true;
            }
        }
    }
}
