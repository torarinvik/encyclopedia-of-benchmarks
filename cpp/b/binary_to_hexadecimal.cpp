/* Convert a most-significant-first bit array to radix 16 text. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t binary_to_hexadecimal(const std::int64_t *bits, std::size_t length,
                                   std::uint8_t *output, std::size_t output_capacity) noexcept
{
    if (length == 0 || length > 63) return -1;
    std::int64_t value = 0;
    for (std::size_t index = 0; index < length; ++index) {
        if (bits[index] < 0 || bits[index] > 1) return -1;
        value = value * 2 + bits[index];
    }
    std::size_t width = 1;
    for (std::int64_t remaining = value; remaining >= 16; remaining /= 16) ++width;
    if (output_capacity < width) return -2;
    std::size_t position = width;
    std::int64_t remaining = value;
    while (position > 0) {
        --position;
        const std::int64_t digit = remaining % 16;
        output[position] = static_cast<std::uint8_t>(digit < 10 ? '0' + digit : 'a' + digit - 10);
        remaining /= 16;
    }
    return static_cast<std::int64_t>(width);
}
