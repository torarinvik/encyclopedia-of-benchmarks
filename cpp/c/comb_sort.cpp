/* Independent portable implementation of TheAlgorithms/C++ comb sort. */
#include <cstddef>
#include <cstdint>

static std::size_t shrink_gap(std::size_t gap) noexcept
{
    return (gap / 13) * 10 + ((gap % 13) * 10) / 13;
}

extern "C" void comb_sort(std::int64_t *values, std::size_t length) noexcept
{
    if (length < 2) return;
    std::size_t gap = length;
    bool swapped = true;
    while (gap > 1 || swapped) {
        gap = shrink_gap(gap);
        if (gap < 1) gap = 1;
        swapped = false;
        for (std::size_t index = 0; index < length - gap; ++index) {
            if (values[index] > values[index + gap]) {
                const std::int64_t temporary = values[index];
                values[index] = values[index + gap];
                values[index + gap] = temporary;
                swapped = true;
            }
        }
    }
}
