/* Independent portable implementation of TheAlgorithms/C selection sort. */
#include <cstddef>
#include <cstdint>

extern "C" void selection_sort(std::int64_t *values, std::size_t length) noexcept
{
    for (std::size_t index = 0; index + 1 < length; ++index) {
        std::size_t minimum = index;
        for (std::size_t probe = index + 1; probe < length; ++probe) {
            if (values[probe] < values[minimum]) minimum = probe;
        }
        if (minimum != index) {
            const std::int64_t temporary = values[index];
            values[index] = values[minimum];
            values[minimum] = temporary;
        }
    }
}
