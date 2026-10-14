/* Write the most-significant-first binary representation of a nonnegative i64. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t decimal_to_binary(std::int64_t value, std::uint8_t *output,
                                           std::size_t output_capacity) noexcept
{
    if (value < 0) return -1;

    std::size_t width = 1;
    for (auto remaining = value; remaining > 1; remaining /= 2) ++width;
    if (output == nullptr || output_capacity < width) return -2;

    std::size_t position = width;
    for (auto remaining = value; position > 0; remaining /= 2)
        output[--position] = static_cast<std::uint8_t>('0' + remaining % 2);
    return static_cast<std::int64_t>(width);
}
