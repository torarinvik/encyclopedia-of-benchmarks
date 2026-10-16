#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t invalid_result = -2'147'483'649;

int hex_digit(std::int64_t code) {
    if (code >= '0' && code <= '9') return static_cast<int>(code - '0');
    if (code >= 'A' && code <= 'F') return static_cast<int>(code - 'A' + 10);
    if (code >= 'a' && code <= 'f') return static_cast<int>(code - 'a' + 10);
    return -1;
}

std::int64_t signed_i32(std::uint32_t bits) {
    return bits <= INT32_MAX ? static_cast<std::int64_t>(bits)
                             : static_cast<std::int64_t>(bits) - INT64_C(4'294'967'296);
}
}

extern "C" std::int64_t hex_to_oct(const std::int64_t* input, std::size_t length) {
    if (length > 8 || (length != 0 && input == nullptr)) return invalid_result;
    std::uint32_t decimal_bits = 0;
    for (std::size_t index = 0; index < length; ++index) {
        const int digit = hex_digit(input[index]);
        if (digit < 0) return invalid_result;
        decimal_bits = decimal_bits * 16u + static_cast<std::uint32_t>(digit);
    }
    std::int64_t decimal = signed_i32(decimal_bits);
    if (decimal <= 0) return 0;

    std::uint32_t octal_bits = 0;
    std::uint32_t place_value = 1;
    while (decimal > 0) {
        octal_bits += static_cast<std::uint32_t>(decimal % 8) * place_value;
        decimal /= 8;
        place_value *= 10u;
    }
    return signed_i32(octal_bits);
}
