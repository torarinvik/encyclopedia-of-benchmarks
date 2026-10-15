/* Apply the case-preserving Atbash mapping to a 7-bit ASCII byte sequence. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t atbash_cipher(const std::int64_t *input, std::size_t length,
                                      std::uint8_t *output, std::size_t output_capacity) noexcept {
    if (length > 66) return -1;
    for (std::size_t index = 0; index < length; ++index)
        if (input[index] < 0 || input[index] > 127) return -1;
    if (output_capacity < length) return -2;
    for (std::size_t index = 0; index < length; ++index) {
        const std::int64_t value = input[index];
        std::int64_t mapped = value;
        if (value >= 65 && value <= 90) mapped = 155 - value;
        else if (value >= 97 && value <= 122) mapped = 219 - value;
        output[index] = static_cast<std::uint8_t>(mapped);
    }
    return static_cast<std::int64_t>(length);
}
