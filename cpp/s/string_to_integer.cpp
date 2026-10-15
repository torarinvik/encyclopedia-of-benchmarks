/* Parse an ASCII byte sequence like C atoi, clamping to signed 32-bit bounds. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_input_length = 4096;
constexpr std::int64_t int32_max_value = 2147483647;
constexpr std::int64_t int32_min_magnitude = 2147483648;
}

extern "C" std::int64_t string_to_integer(const std::int64_t *input,
        std::size_t length) noexcept {
    if (length > max_input_length || (length != 0 && input == nullptr)) return -2;
    for (std::size_t index = 0; index < length; ++index)
        if (input[index] < 1 || input[index] > 127) return -2;

    std::size_t index = 0;
    while (index < length && input[index] == ' ') ++index;
    bool negative = false;
    if (index < length && (input[index] == '+' || input[index] == '-')) {
        negative = input[index] == '-';
        ++index;
    }
    const auto limit = negative ? int32_min_magnitude : int32_max_value;
    std::int64_t magnitude = 0;
    while (index < length && input[index] >= '0' && input[index] <= '9') {
        const auto digit = input[index] - '0';
        if (magnitude > limit / 10 || (magnitude == limit / 10 && digit > limit % 10))
            return negative ? -int32_min_magnitude : int32_max_value;
        magnitude = magnitude * 10 + digit;
        ++index;
    }
    return negative ? -magnitude : magnitude;
}
