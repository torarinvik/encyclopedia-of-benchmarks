/* Selection sort variant that reverses each prefix to place its minimum. */
#include <cstddef>
#include <cstdint>

extern "C" void reverse_selection(std::int64_t *values, std::size_t length) noexcept
{
    if (length < 2) return;
    for (std::size_t start = 0; start + 1 < length; ++start) {
        std::size_t minimum = start;
        for (std::size_t scan = start + 1; scan < length; ++scan) {
            if (values[scan] < values[minimum]) minimum = scan;
        }
        std::size_t left = start;
        std::size_t right = minimum;
        while (left < right) {
            const std::int64_t temporary = values[left];
            values[left] = values[right];
            values[right] = temporary;
            ++left;
            --right;
        }
    }
}
