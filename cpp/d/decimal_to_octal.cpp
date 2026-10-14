/* Write the octal digits of a nonnegative signed 64-bit input. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t decimal_to_octal(std::int64_t value, std::uint8_t *output,
                                          std::size_t output_capacity) noexcept
{
    if (value < 0) return -1;
    std::size_t width = 1;
    for (auto remaining = value; remaining >= 8; remaining /= 8) ++width;
    if (output == nullptr || output_capacity < width) return -2;
    std::size_t position = width;
    for (auto remaining = value; position > 0; remaining /= 8)
        output[--position] = static_cast<std::uint8_t>('0' + remaining % 8);
    return static_cast<std::int64_t>(width);
}
