/* Recursive selection sort for the shared signed 64-bit benchmark contract. */
#include <cstddef>
#include <cstdint>

namespace {
std::size_t minimum_index(const std::int64_t *values, std::size_t start, std::size_t end) noexcept
{
    if (start + 1 >= end) return start;
    const std::size_t minimum = minimum_index(values, start + 1, end);
    return values[start] < values[minimum] ? start : minimum;
}

void selection_sort_range(std::int64_t *values, std::size_t start, std::size_t length) noexcept
{
    if (start + 1 >= length) return;
    const std::size_t minimum = minimum_index(values, start, length);
    if (minimum != start) {
        const std::int64_t temporary = values[start];
        values[start] = values[minimum];
        values[minimum] = temporary;
    }
    selection_sort_range(values, start + 1, length);
}
}

extern "C" void selection_sort_recursive(std::int64_t *values, std::size_t length) noexcept
{
    selection_sort_range(values, 0, length);
}
