/* Write lowercase hexadecimal digits of a nonnegative signed 64-bit input. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t decimal_to_hexadecimal(std::int64_t value, std::uint8_t *output,
                                                std::size_t output_capacity) noexcept
{
    if (value < 0) return -1;
    std::size_t width = 1;
    for (auto remaining = value; remaining >= 16; remaining /= 16) ++width;
    if (output == nullptr || output_capacity < width) return -2;
    std::size_t position = width;
    for (auto remaining = value; position > 0; remaining /= 16) {
        const auto digit = remaining % 16;
        output[--position] = static_cast<std::uint8_t>(digit < 10 ? '0' + digit : 'a' + digit - 10);
    }
    return static_cast<std::int64_t>(width);
}
