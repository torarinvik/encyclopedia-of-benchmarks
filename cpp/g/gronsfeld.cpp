/* Encrypt ASCII letters with a repeating decimal-digit Gronsfeld key. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t gronsfeld(const std::int64_t *input, std::size_t length,
                                    std::uint8_t *output,
                                    std::size_t output_capacity) noexcept {
    if (input == nullptr || length < 2 || length > 321) return -1;
    std::size_t separator = 0;
    while (separator < length && input[separator] != 0) ++separator;
    if (separator == length) return -1;
    const std::size_t text_length = separator;
    const std::size_t key_length = length - separator - 1;
    if (text_length > 256 || key_length < 1 || key_length > 64) return -1;

    for (std::size_t index = 0; index < text_length; ++index)
        if (input[index] < 1 || input[index] > 127) return -1;
    for (std::size_t index = 0; index < key_length; ++index) {
        const std::int64_t value = input[separator + 1 + index];
        if (value < 48 || value > 57) return -1;
    }
    if (output_capacity < text_length || (text_length > 0 && output == nullptr)) return -2;

    std::size_t key_index = 0;
    for (std::size_t index = 0; index < text_length; ++index) {
        const std::int64_t value = input[index];
        std::int64_t mapped = value;
        if (value >= 65 && value <= 90) {
            const std::int64_t shift = input[separator + 1 + key_index % key_length] - 48;
            mapped = 65 + (value - 65 + shift) % 26;
            ++key_index;
        } else if (value >= 97 && value <= 122) {
            const std::int64_t shift = input[separator + 1 + key_index % key_length] - 48;
            mapped = 97 + (value - 97 + shift) % 26;
            ++key_index;
        }
        output[index] = static_cast<std::uint8_t>(mapped);
    }
    return static_cast<std::int64_t>(text_length);
}
