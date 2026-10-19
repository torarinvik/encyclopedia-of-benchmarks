/* Bounded port of BitBench drop3: discard 3-bit codes below 4. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t drop3(const std::int64_t *values, std::size_t length) noexcept
{
    constexpr std::size_t max_input = 4096;
    constexpr unsigned offsets[8] = {0, 5, 2, 7, 4, 1, 6, 3};
    if (length > max_input + 1 || (length != 0 && values == nullptr)) return -1;
    for (std::size_t i = 0; i < length; ++i)
        if (values[i] < 0 || values[i] > 255) return -1;
    if (length > max_input) return -1;

    std::int64_t output_size = 0;
    for (int iteration = 0; iteration < 20; ++iteration) {
        std::size_t input_index = 0;
        std::size_t remaining_bits = length * 8;
        unsigned phase = 0;
        std::uint16_t bit_buffer = 0;
        int output_bits = 0;
        while (remaining_bits >= 3) {
            remaining_bits -= 3;
            const unsigned offset = offsets[phase];
            if (offset < 3)
                bit_buffer = static_cast<std::uint16_t>(bit_buffer |
                    (static_cast<std::uint16_t>(values[input_index++]) << (8 - offset)));
            const unsigned code = (bit_buffer >> 13) & 7u;
            if (code >= 4) output_bits += 3;
            bit_buffer = static_cast<std::uint16_t>(bit_buffer << 3);
            phase = (phase + 1) & 7u;
        }
        output_size = output_bits >> 3;
    }
    return output_size;
}
