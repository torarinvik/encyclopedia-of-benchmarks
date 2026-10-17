#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_string_length = 256;
constexpr std::size_t max_parseable_input_length = 259;
}

extern "C" std::int64_t string_left_rotation(const std::int64_t* input, std::size_t length,
                                              std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || length < 2 || length > max_parseable_input_length) return -1;
    const std::int64_t raw_length = input[0], raw_rotation = input[1];
    if (raw_length < 0 || raw_length > std::int64_t(max_string_length) || raw_rotation < 0 ||
        raw_rotation > raw_length || length != std::size_t(raw_length) + 2) return -1;

    const std::size_t text_length = std::size_t(raw_length), rotation = std::size_t(raw_rotation);
    std::uint16_t units[max_string_length]{};
    for (std::size_t i = 0; i < text_length; ++i) {
        if (input[i + 2] < 0 || input[i + 2] > 65535) return -1;
        units[i] = std::uint16_t(input[i + 2]);
    }
    const std::size_t required = text_length * 2;
    if (required == 0) return 0;
    if (output == nullptr || capacity < required) return -2;
    for (std::size_t i = 0; i < text_length; ++i) {
        std::size_t source = rotation + i;
        if (source >= text_length) source -= text_length;
        const std::uint16_t value = units[source];
        output[2 * i] = std::uint8_t(value & 255);
        output[2 * i + 1] = std::uint8_t(value >> 8);
    }
    return std::int64_t(required);
}
