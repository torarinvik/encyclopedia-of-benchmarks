/* Apply case-preserving ROT13 to a non-NUL ASCII byte sequence. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t rot13(const std::int64_t *input, std::size_t length,
                                std::uint8_t *output, std::size_t output_capacity) noexcept {
    if (length > 66) return -1;
    for (std::size_t index = 0; index < length; ++index)
        if (input[index] < 1 || input[index] > 127) return -1;
    if (output_capacity < length) return -2;
    for (std::size_t index = 0; index < length; ++index) {
        const std::int64_t value = input[index];
        std::int64_t mapped = value;
        if (value >= 'A' && value <= 'Z') mapped = 'A' + (value - 'A' + 13) % 26;
        else if (value >= 'a' && value <= 'z') mapped = 'a' + (value - 'a' + 13) % 26;
        output[index] = static_cast<std::uint8_t>(mapped);
    }
    return static_cast<std::int64_t>(length);
}
