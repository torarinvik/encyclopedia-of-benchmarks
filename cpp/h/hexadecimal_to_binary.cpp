/* Convert a most-significant-first hexadecimal digit array to radix 2 text. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t hexadecimal_to_binary(const std::int64_t *digits, std::size_t length,
                                   std::uint8_t *output, std::size_t output_capacity) noexcept
{
    if (length == 0 || length > 16) return -1;
    if (length == 16 && digits[0] > 7) return -1;
    std::int64_t value = 0;
    for (std::size_t index = 0; index < length; ++index) {
        if (digits[index] < 0 || digits[index] > 15) return -1;
        value = value * 16 + digits[index];
    }
    std::size_t width = 1;
    for (std::int64_t remaining = value; remaining >= 2; remaining /= 2) ++width;
    if (output_capacity < width) return -2;
    std::size_t position = width;
    std::int64_t remaining = value;
    while (position > 0) {
        --position;
        const std::int64_t digit = remaining % 2;
        output[position] = static_cast<std::uint8_t>(digit < 10 ? '0' + digit : 'a' + digit - 10);
        remaining /= 2;
    }
    return static_cast<std::int64_t>(width);
}
