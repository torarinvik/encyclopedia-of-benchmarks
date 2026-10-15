#include <cstddef>
#include <cstdint>

// Write the minimal-width ASCII binary form of n ^ (n >> 1).
extern "C" std::int64_t decimal_to_gray(std::int64_t value, std::uint8_t *output,
                                         std::size_t output_capacity) noexcept
{
    if (value < 0) return -1;

    const std::int64_t gray = value ^ (value >> 1);
    std::size_t width = 1;
    for (std::int64_t remaining = gray; remaining > 1; remaining /= 2) ++width;
    if (output == nullptr || output_capacity < width) return -2;

    std::size_t position = width;
    for (std::int64_t remaining = gray; position > 0; remaining /= 2)
        output[--position] = static_cast<std::uint8_t>('0' + remaining % 2);
    return static_cast<std::int64_t>(width);
}
