/* Write the prefixed four-bit-per-decimal-digit BCD representation. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t binary_coded_decimal(std::int64_t value, std::uint8_t *output,
                                               std::size_t output_capacity) noexcept
{
    if (value < INT32_MIN || value > INT32_MAX) return -1;
    if (value < 0) value = 0;

    std::uint8_t digits[10];
    std::size_t digit_count = 0;
    do {
        digits[digit_count++] = static_cast<std::uint8_t>(value % 10);
        value /= 10;
    } while (value > 0);

    const std::size_t output_length = 2 + digit_count * 4;
    if (output == nullptr || output_capacity < output_length) return -2;
    output[0] = static_cast<std::uint8_t>('0');
    output[1] = static_cast<std::uint8_t>('b');
    std::size_t position = 2;
    while (digit_count > 0) {
        const std::uint8_t digit = digits[--digit_count];
        for (int bit = 3; bit >= 0; --bit)
            output[position++] = static_cast<std::uint8_t>('0' + ((digit >> bit) & 1));
    }
    return static_cast<std::int64_t>(output_length);
}
