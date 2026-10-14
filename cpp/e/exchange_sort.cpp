/* Portable exchange sort for the shared signed 64-bit benchmark contract. */
#include <cstddef>
#include <cstdint>

extern "C" void exchange_sort(std::int64_t *values, std::size_t length) noexcept
{
    if (length < 2) return;
    const std::size_t last = length - 1;
    for (std::size_t first = 0; first < last; ++first) {
        for (std::size_t other = first + 1; other < length; ++other) {
            if (values[other] < values[first]) {
                const std::int64_t temporary = values[first];
                values[first] = values[other];
                values[other] = temporary;
            }
        }
    }
}
