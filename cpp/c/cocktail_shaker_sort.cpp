/* Stable full-range bidirectional adjacent-swap sort. */
#include <cstddef>
#include <cstdint>

extern "C" void cocktail_shaker_sort(std::int64_t *values, std::size_t length) noexcept
{
    if (length < 2) return;
    for (;;) {
        bool swapped = false;
        for (std::size_t index = 0; index + 1 < length; ++index) {
            if (values[index] > values[index + 1]) {
                const std::int64_t temporary = values[index];
                values[index] = values[index + 1];
                values[index + 1] = temporary;
                swapped = true;
            }
        }
        if (!swapped) break;
        swapped = false;
        std::size_t index = length - 1;
        while (index > 0) {
            if (values[index - 1] > values[index]) {
                const std::int64_t temporary = values[index - 1];
                values[index - 1] = values[index];
                values[index] = temporary;
                swapped = true;
            }
            --index;
        }
        if (!swapped) break;
    }
}
