/* Brute-force next-greater-value search for each node in list order. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t next_greater_nodes(const std::int64_t *values,
                                           std::size_t length,
                                           std::uint8_t *output,
                                           std::size_t output_capacity) noexcept
{
    if (length == 0 || length > 4096 || values == nullptr) return -1;
    for (std::size_t index = 0; index < length; ++index)
        if (values[index] < 1 || values[index] > 1000000000) return -1;
    if (output_capacity < 4 * length || output == nullptr) return -2;
    for (std::size_t index = 0; index < length; ++index) {
        std::int64_t next_greater = 0;
        for (std::size_t later = index + 1; later < length; ++later) {
            if (values[later] > values[index]) {
                next_greater = values[later];
                break;
            }
        }
        const auto encoded = static_cast<std::uint32_t>(next_greater);
        output[4 * index] = static_cast<std::uint8_t>(encoded & 0xffU);
        output[4 * index + 1] = static_cast<std::uint8_t>((encoded >> 8) & 0xffU);
        output[4 * index + 2] = static_cast<std::uint8_t>((encoded >> 16) & 0xffU);
        output[4 * index + 3] = static_cast<std::uint8_t>((encoded >> 24) & 0xffU);
    }
    return static_cast<std::int64_t>(length);
}
