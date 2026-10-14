/* Bead sort for the benchmark's nonnegative 0..63 domain. */
#include <cstddef>
#include <cstdint>

extern "C" void bead_sort(std::int64_t *values, std::int64_t *scratch, std::size_t length) noexcept
{
    if (length < 2) return;
    for (std::size_t level = 0; level < 64; ++level) scratch[level] = 0;
    for (std::size_t index = 0; index < length; ++index) {
        for (std::int64_t level = 0; level < values[index]; ++level) ++scratch[static_cast<std::size_t>(level)];
    }
    for (std::size_t index = 0; index < length; ++index) {
        const std::size_t row_from_bottom = length - 1 - index;
        std::int64_t value = 0;
        for (std::size_t level = 0; level < 64; ++level) {
            if (scratch[level] > static_cast<std::int64_t>(row_from_bottom)) ++value;
        }
        values[index] = value;
    }
}
