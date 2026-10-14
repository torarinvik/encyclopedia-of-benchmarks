/* Apply ROT13 only to lowercase non-NUL ASCII bytes. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t theoretical_rot13(const std::int64_t *input, std::size_t length,
                                            std::uint8_t *output,
                                            std::size_t output_capacity) noexcept {
    if (length > 66) return -1;
    for (std::size_t index = 0; index < length; ++index)
        if (input[index] < 1 || input[index] > 127) return -1;
    if (output_capacity < length) return -2;
    for (std::size_t index = 0; index < length; ++index) {
        const std::int64_t value = input[index];
        const std::int64_t mapped = value >= 'a' && value <= 'z'
            ? 'a' + (value - 'a' + 13) % 26 : value;
        output[index] = static_cast<std::uint8_t>(mapped);
    }
    return static_cast<std::int64_t>(length);
}
