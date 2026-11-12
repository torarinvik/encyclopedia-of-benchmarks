#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_output_bytes = 41;
}

extern "C" std::int64_t balanced_ternary_conversion(const std::int64_t* input,
        std::size_t length, std::uint8_t* output, std::size_t capacity) noexcept {
    if (input == nullptr || length != 1) return -1;
    std::array<std::uint8_t, max_output_bytes> reversed{};
    std::size_t digit_count = 0;
    auto value = input[0];
    if (value == 0) reversed[digit_count++] = static_cast<std::uint8_t>('0');
    while (value != 0) {
        auto quotient = value / 3;
        const auto remainder = value % 3;
        std::uint8_t digit;
        if (remainder == 2) { digit = static_cast<std::uint8_t>('Z'); ++quotient; }
        else if (remainder == -2) { digit = static_cast<std::uint8_t>('1'); --quotient; }
        else if (remainder == -1) digit = static_cast<std::uint8_t>('Z');
        else if (remainder == 0) digit = static_cast<std::uint8_t>('0');
        else digit = static_cast<std::uint8_t>('1');
        reversed[digit_count++] = digit;
        value = quotient;
    }
    if (output == nullptr || capacity < digit_count) return -2;
    for (std::size_t index = 0; index < digit_count; ++index)
        output[index] = reversed[digit_count - index - 1];
    return static_cast<std::int64_t>(digit_count);
}
