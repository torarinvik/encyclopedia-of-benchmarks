#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_values = 256;

void bubble_sort_recursive_impl(std::int64_t *values, std::size_t length)
{
    if (length <= 1) {
        return;
    }

    bool swapped = false;
    for (std::size_t index = 0; index + 1 < length; ++index) {
        if (values[index] > values[index + 1]) {
            const std::int64_t temporary = values[index];
            values[index] = values[index + 1];
            values[index + 1] = temporary;
            swapped = true;
        }
    }
    if (swapped) {
        bubble_sort_recursive_impl(values, length - 1);
    }
}
}

extern "C" void bubble_sort_recursive(std::int64_t *values, std::size_t length)
{
    if (length <= max_values) {
        bubble_sort_recursive_impl(values, length);
    }
}
