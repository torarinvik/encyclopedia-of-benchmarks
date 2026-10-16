#include <cstddef>
#include <cstdint>

namespace { constexpr std::size_t rgb_hex_output_length = 7; }

static std::uint8_t hex_digit(std::int64_t value) noexcept {
    return static_cast<std::uint8_t>(value < 10 ? '0' + value : 'a' + value - 10);
}

extern "C" std::int64_t rgbto_hex(const std::int64_t *input, std::size_t length,
                                  std::uint8_t *output, std::size_t capacity) noexcept {
    if (length != 3 || input == nullptr) return -1;
    for (std::size_t i = 0; i < 3; ++i)
        if (input[i] < 0 || input[i] > 255) return -1;
    if (capacity < rgb_hex_output_length || output == nullptr) return -2;
    output[0] = '#';
    for (std::size_t i = 0; i < 3; ++i) {
        output[1 + 2 * i] = hex_digit(input[i] >> 4);
        output[2 + 2 * i] = hex_digit(input[i] & 15);
    }
    return static_cast<std::int64_t>(rgb_hex_output_length);
}
