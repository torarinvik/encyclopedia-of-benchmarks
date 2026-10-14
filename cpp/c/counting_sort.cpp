/* Counting sort for signed keys in the inclusive range [-128, 128]. */
#include <cstddef>
#include <cstdint>

extern "C" void counting_sort(std::int64_t *values, std::int64_t *counts, std::size_t length) noexcept
{
    for (std::size_t bucket = 0; bucket < 257; ++bucket) counts[bucket] = 0;
    for (std::size_t index = 0; index < length; ++index) {
        const std::size_t bucket = static_cast<std::size_t>(values[index] + 128);
        ++counts[bucket];
    }
    std::size_t output = 0;
    for (std::size_t bucket = 0; bucket < 257; ++bucket) {
        while (counts[bucket] > 0) {
            values[output++] = static_cast<std::int64_t>(bucket) - 128;
            --counts[bucket];
        }
    }
}
