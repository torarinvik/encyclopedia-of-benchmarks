/* Convert a nonnegative signed 64-bit value to base 2 through 36. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t decimal_to_any_base(const std::int64_t *input, std::size_t length,
                                              std::uint8_t *output, std::size_t output_capacity) noexcept
{
    if (input == nullptr || length != 2) return -1;
    const std::int64_t value = input[0], base = input[1];
    if (value < 0 || base < 2 || base > 36) return -1;
    std::size_t width = 1;
    for (std::int64_t remaining = value; remaining >= base; remaining /= base) ++width;
    if (output == nullptr || output_capacity < width) return -2;
    std::size_t position = width;
    std::int64_t remaining = value;
    while (position > 0) {
        --position;
        const std::int64_t digit = remaining % base;
        output[position] = static_cast<std::uint8_t>(digit < 10 ? '0' + digit : 'A' + digit - 10);
        remaining /= base;
    }
    return static_cast<std::int64_t>(width);
}
