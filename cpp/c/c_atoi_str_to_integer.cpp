/* Parse a length-prefixed byte string with C atoi whitespace and NUL semantics. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_input_length = 4096;
constexpr std::int64_t int32_max_value = 2147483647;
constexpr std::int64_t int32_min_magnitude = 2147483648;
bool is_ascii_space(std::int64_t value) noexcept { return (value >= 9 && value <= 13) || value == 32; }
}

extern "C" std::int64_t c_atoi_str_to_integer(const std::int64_t *input,
    std::size_t length) noexcept {
    if (length > max_input_length || (length != 0 && input == nullptr)) return -2;
    for (std::size_t position = 0; position < length; ++position)
        if (input[position] < 0 || input[position] > 127) return -2;
    std::size_t index = 0;
    while (index < length && input[index] != 0 && is_ascii_space(input[index])) ++index;
    bool negative = false;
    if (index < length && input[index] != 0 && (input[index] == '+' || input[index] == '-')) {
        negative = input[index] == '-';
        ++index;
    }
    const auto limit = negative ? int32_min_magnitude : int32_max_value;
    std::int64_t magnitude = 0;
    while (index < length && input[index] != 0 && input[index] >= '0' && input[index] <= '9') {
        const auto digit = input[index] - '0';
        if (magnitude > limit / 10 || (magnitude == limit / 10 && digit > limit % 10))
            return negative ? -int32_min_magnitude : int32_max_value;
        magnitude = magnitude * 10 + digit;
        ++index;
    }
    return negative ? -magnitude : magnitude;
}
