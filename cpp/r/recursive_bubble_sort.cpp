/* Recursive bubble sort for the shared signed 64-bit benchmark contract. */
#include <cstddef>
#include <cstdint>

namespace {
void recursive_bubble_sort_range(std::int64_t *values, std::size_t length) noexcept
{
    if (length < 2) return;
    for (std::size_t index = 0; index + 1 < length; ++index) {
        if (values[index] > values[index + 1]) {
            const std::int64_t temporary = values[index];
            values[index] = values[index + 1];
            values[index + 1] = temporary;
        }
    }
    recursive_bubble_sort_range(values, length - 1);
}
}

extern "C" void recursive_bubble_sort(std::int64_t *values, std::size_t length) noexcept
{
    recursive_bubble_sort_range(values, length);
}
