/* Portable pigeonhole sort for signed keys in [-128, 128]. */
#include <cstddef>
#include <cstdint>

extern "C" void pigeonhole_sort(std::int64_t *values, std::int64_t *scratch, std::size_t length) noexcept
{
    if (length < 2) return;
    for (std::size_t bucket = 0; bucket < 257; ++bucket) scratch[bucket] = 0;
    for (std::size_t index = 0; index < length; ++index) {
        const std::size_t bucket = static_cast<std::size_t>(values[index] + 128);
        ++scratch[bucket];
    }
    std::size_t index = 0;
    for (std::size_t bucket = 0; bucket < 257; ++bucket) {
        while (scratch[bucket] > 0) {
            values[index++] = static_cast<std::int64_t>(bucket) - 128;
            --scratch[bucket];
        }
    }
}
