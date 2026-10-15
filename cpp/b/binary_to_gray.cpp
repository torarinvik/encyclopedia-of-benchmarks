// Convert an ASCII binary string to equal-width ASCII Gray code.
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t binary_to_gray(const std::int64_t *bits, std::size_t length,
                                        std::uint8_t *output, std::size_t output_capacity) noexcept
{
    if (bits == nullptr || length == 0 || length > 66) return -1;
    for (std::size_t index = 0; index < length; ++index)
        if (bits[index] != '0' && bits[index] != '1') return -1;
    if (output == nullptr || output_capacity < length) return -2;
    for (std::size_t index = 0; index < length; ++index) {
        const int current = static_cast<int>(bits[index] - '0');
        const int previous = index == 0 ? 0 : static_cast<int>(bits[index - 1] - '0');
        output[index] = static_cast<std::uint8_t>('0' + (current ^ previous));
    }
    return static_cast<std::int64_t>(length);
}
