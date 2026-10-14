/* In-place cycle sort for signed 64-bit values. */
#include <cstddef>
#include <cstdint>

extern "C" void cycle_sort(std::int64_t *values, std::size_t length) noexcept
{
    if (length < 2) return;
    for (std::size_t cycle_start = 0; cycle_start < length - 1; ++cycle_start) {
        std::int64_t item = values[cycle_start];
        std::size_t position = cycle_start;
        for (std::size_t scan = cycle_start + 1; scan < length; ++scan) {
            if (values[scan] < item) ++position;
        }
        if (position == cycle_start) continue;
        while (position < length && item == values[position]) ++position;
        if (position == length) continue;
        std::int64_t temporary = values[position];
        values[position] = item;
        item = temporary;
        while (position != cycle_start) {
            position = cycle_start;
            for (std::size_t scan = cycle_start + 1; scan < length; ++scan) {
                if (values[scan] < item) ++position;
            }
            while (position < length && item == values[position]) ++position;
            if (position == length) break;
            temporary = values[position];
            values[position] = item;
            item = temporary;
        }
    }
}
