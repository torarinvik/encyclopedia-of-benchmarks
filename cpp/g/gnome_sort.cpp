/* Independent portable implementation of TheAlgorithms/C++ gnome sort. */
#include <cstddef>
#include <cstdint>

extern "C" void gnome_sort(std::int64_t *values, std::size_t length) noexcept
{
    if (length < 2) return;
    std::size_t position = 1;
    while (position < length) {
        if (values[position] >= values[position - 1]) {
            ++position;
        } else {
            const std::int64_t temporary = values[position - 1];
            values[position - 1] = values[position];
            values[position] = temporary;
            if (position > 1) --position;
            else position = 1;
        }
    }
}
