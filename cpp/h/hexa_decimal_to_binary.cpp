#include <cstddef>
#include <cstdint>

namespace {
int hex_digit(std::int64_t code) {
    if (code >= '0' && code <= '9') return static_cast<int>(code - '0');
    if (code >= 'A' && code <= 'F') return static_cast<int>(code - 'A' + 10);
    if (code >= 'a' && code <= 'f') return static_cast<int>(code - 'a' + 10);
    return -1;
}
}

extern "C" std::int64_t hexa_decimal_to_binary(const std::int64_t* input, std::size_t length,
                                                std::uint8_t* output, std::size_t output_capacity) {
    if (input == nullptr || length == 0 || length > 65) return -1;
    std::size_t first_digit = 0;
    bool negative = false;
    if (input[0] == '-') { negative = true; first_digit = 1; }
    else if (input[0] == '+') first_digit = 1;
    if (first_digit == length) return -1;
    std::uint64_t value = 0;
    const std::uint64_t limit = negative ? UINT64_C(2147483648) : static_cast<std::uint64_t>(INT32_MAX);
    for (std::size_t index = first_digit; index < length; ++index) {
        const int digit = hex_digit(input[index]);
        if (digit < 0 || value > (limit - static_cast<std::uint64_t>(digit)) / 16) return -1;
        value = value * 16 + static_cast<std::uint64_t>(digit);
    }
    const std::uint32_t bits = negative ? 0u - static_cast<std::uint32_t>(value) : static_cast<std::uint32_t>(value);
    std::size_t width = 0;
    for (std::uint32_t remaining = bits; remaining != 0; remaining >>= 1) ++width;
    if (negative && value != 0) width = 32;
    else if (width < 8) width = 8;
    std::uint8_t buffer[32];
    std::uint32_t remaining = bits;
    for (std::size_t position = width; position > 0;) {
        --position;
        buffer[position] = static_cast<std::uint8_t>('0' + remaining % 2);
        remaining /= 2;
    }
    if (width > output_capacity || output == nullptr) return -2;
    for (std::size_t index = 0; index < width; ++index) output[index] = buffer[index];
    return static_cast<std::int64_t>(width);
}
