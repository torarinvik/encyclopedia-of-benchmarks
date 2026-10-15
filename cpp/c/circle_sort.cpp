/* Portable recursive circle sort for signed 64-bit values. */
#include <cstddef>
#include <cstdint>

static bool circle_sort_range(std::int64_t *values, std::size_t left_value, std::size_t right_value) noexcept
{
    if (left_value >= right_value) return false;

    std::size_t low = left_value;
    std::size_t high = right_value;
    bool swapped = false;
    while (low < high) {
        if (values[low] > values[high]) {
            const std::int64_t temporary = values[low];
            values[low] = values[high];
            values[high] = temporary;
            swapped = true;
        }
        ++low;
        --high;
    }
    if (low == high && values[low] > values[high + 1]) {
        const std::int64_t temporary = values[low];
        values[low] = values[high + 1];
        values[high + 1] = temporary;
        swapped = true;
    }

    const std::size_t middle = left_value + (right_value - left_value) / 2;
    const bool left_swapped = circle_sort_range(values, left_value, middle);
    const bool right_swapped = circle_sort_range(values, middle + 1, right_value);
    return swapped || left_swapped || right_swapped;
}

extern "C" void circle_sort(std::int64_t *values, std::size_t length) noexcept
{
    if (length < 2) return;
    while (circle_sort_range(values, 0, length - 1)) {}
}
