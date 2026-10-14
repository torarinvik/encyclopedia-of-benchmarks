/* Portable stooge sort using half-open subranges. */
#include <cstddef>
#include <cstdint>

static void stooge_sort_range(std::int64_t *values, std::size_t low, std::size_t high) noexcept
{
    const std::size_t length = high - low;
    if (length < 2) return;
    if (values[low] > values[high - 1]) {
        const std::int64_t temporary = values[low];
        values[low] = values[high - 1];
        values[high - 1] = temporary;
    }
    if (length > 2) {
        const std::size_t third = length / 3;
        stooge_sort_range(values, low, high - third);
        stooge_sort_range(values, low + third, high);
        stooge_sort_range(values, low, high - third);
    }
}

extern "C" void stooge_sort(std::int64_t *values, std::size_t length) noexcept
{
    if (length > 1) stooge_sort_range(values, 0, length);
}
