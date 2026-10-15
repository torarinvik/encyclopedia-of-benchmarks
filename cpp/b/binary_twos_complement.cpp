// Emit the pinned minimal-width two's-complement string for a signed integer.
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t twos_complement(std::int64_t value, std::uint8_t *output,
                                         std::size_t output_capacity) noexcept {
    if (value > 0) return -1;
    if (value == 0) {
        if (output == nullptr || output_capacity < 3) return -2;
        output[0] = '0'; output[1] = 'b'; output[2] = '0';
        return 3;
    }
    const auto magnitude = static_cast<std::uint64_t>(-(value + 1)) + 1;
    std::size_t bit_length = 0;
    for (auto remaining = magnitude; remaining != 0; remaining >>= 1) ++bit_length;
    const auto suffix = bit_length == 64 ? magnitude : (UINT64_C(1) << bit_length) - magnitude;
    std::uint8_t bits[64];
    std::size_t bit_count = 0;
    for (auto remaining = suffix; remaining != 0; remaining >>= 1)
        bits[bit_count++] = static_cast<std::uint8_t>('0' + (remaining & 1U));
    const std::size_t required = bit_length + 3;
    if (output == nullptr || output_capacity < required) return -2;
    std::size_t position = 0;
    output[position++] = '0'; output[position++] = 'b'; output[position++] = '1';
    for (std::size_t zero = bit_count; zero < bit_length; ++zero) output[position++] = '0';
    while (bit_count > 0) output[position++] = bits[--bit_count];
    return static_cast<std::int64_t>(position);
}
