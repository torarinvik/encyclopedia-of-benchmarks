#include <cstddef>
#include <cstdint>

extern "C" std::int64_t tokenize_string(const std::int64_t *input, std::size_t length,
                                         std::uint8_t *output, std::size_t capacity) {
    if (input == nullptr || length < 2 || length > 130) return -1;
    if (input[0] < 0 || input[0] > 128 || length != 2 + static_cast<std::size_t>(input[0])) return -1;
    const std::int64_t separator = input[1];
    if (separator != 44 && separator != 46 && separator != 58) return -1;
    std::size_t separator_count = 0;
    for (std::size_t i = 0; i < static_cast<std::size_t>(input[0]); ++i) {
        const std::int64_t byte = input[i + 2];
        if (byte < 32 || byte > 126) return -1;
        if (byte == separator) ++separator_count;
    }
    if (separator_count > 18) return -1;
    const std::size_t output_length = static_cast<std::size_t>(input[0]) + 2;
    if (output == nullptr || capacity < output_length) return -2;
    output[0] = static_cast<std::uint8_t>(separator_count + 1);
    for (std::size_t i = 0; i < static_cast<std::size_t>(input[0]); ++i)
        output[i + 1] = input[i + 2] == separator ? 0 : static_cast<std::uint8_t>(input[i + 2]);
    output[output_length - 1] = 0;
    return static_cast<std::int64_t>(output_length);
}
