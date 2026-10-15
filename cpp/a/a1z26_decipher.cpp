/* Decode one-based alphabet positions as lowercase ASCII letters. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t a1z26_decipher(const std::int64_t *input, std::size_t length,
                                       std::uint8_t *output, std::size_t output_capacity) noexcept {
    if (length > 66) return -1;
    for (std::size_t index = 0; index < length; ++index)
        if (input[index] < 1 || input[index] > 26) return -1;
    if (output_capacity < length) return -2;
    for (std::size_t index = 0; index < length; ++index)
        output[index] = static_cast<std::uint8_t>(96 + input[index]);
    return static_cast<std::int64_t>(length);
}
