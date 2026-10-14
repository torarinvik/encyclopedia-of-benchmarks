/* Recursive circle sort for the shared signed 64-bit benchmark contract. */
#include <cstddef>
#include <cstdint>

namespace {
bool circle_pass(std::int64_t *values, std::size_t low, std::size_t high) noexcept
{
    const std::size_t length = high - low;
    if (length < 2) return false;
    bool swapped = false;
    std::size_t left = low;
    std::size_t right = high - 1;
    while (left < right) {
        if (values[left] > values[right]) {
            const std::int64_t temporary = values[left];
            values[left] = values[right];
            values[right] = temporary;
            swapped = true;
        }
        ++left;
        --right;
    }
    if ((length & 1U) != 0 && left == right && right + 1 < high &&
        values[right + 1] < values[right]) {
        const std::int64_t temporary = values[right];
        values[right] = values[right + 1];
        values[right + 1] = temporary;
        swapped = true;
    }
    const std::size_t split = low + length / 2 + length % 2;
    const bool left_swapped = circle_pass(values, low, split);
    const bool right_swapped = circle_pass(values, split, high);
    return swapped || left_swapped || right_swapped;
}
}

extern "C" void circle_sort(std::int64_t *values, std::size_t length) noexcept
{
    while (length > 1 && circle_pass(values, 0, length)) { }
}
