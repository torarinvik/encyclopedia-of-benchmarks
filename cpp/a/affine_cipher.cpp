/* Apply an affine substitution over a caller-supplied printable ASCII alphabet. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_input_values = 612;
constexpr std::size_t max_text_length = 512;

std::int64_t gcd_i64(std::int64_t left, std::int64_t right) noexcept
{
    while (right != 0) {
        const auto remainder = left % right;
        left = right;
        right = remainder;
    }
    return left;
}

std::int64_t inverse_mod(std::int64_t value, std::int64_t modulus) noexcept
{
    for (std::int64_t candidate = 1; candidate < modulus; ++candidate)
        if ((value * candidate) % modulus == 1) return candidate;
    return -1;
}
}

extern "C" std::int64_t affine_cipher(const std::int64_t *values, std::size_t length,
                                      std::uint8_t *output, std::size_t output_capacity) noexcept
{
    if (values == nullptr || length < 7 || length > max_input_values) return -1;
    const auto mode = values[0], key_a = values[1], key_b = values[2], alphabet_arg = values[3];
    if (mode < 0 || mode > 1 || alphabet_arg < 2 || alphabet_arg > 95) return -1;
    const auto alphabet_length = static_cast<std::size_t>(alphabet_arg);
    const auto text_length_index = 4 + alphabet_length;
    if (length <= text_length_index) return -1;
    const auto text_length_arg = values[text_length_index];
    if (key_a < 0 || key_a > 1000000 || key_b < 0 || key_b >= alphabet_arg ||
        text_length_arg < 0 || text_length_arg > static_cast<std::int64_t>(max_text_length) ||
        length != text_length_index + 1 + static_cast<std::size_t>(text_length_arg) ||
        gcd_i64(key_a, alphabet_arg) != 1) return -1;
    const auto text_length = static_cast<std::size_t>(text_length_arg);

    std::int16_t positions[128];
    for (std::size_t code = 0; code < 128; ++code) positions[code] = -1;
    for (std::size_t index = 0; index < alphabet_length; ++index) {
        const auto symbol = values[4 + index];
        if (symbol < 32 || symbol > 126 || positions[static_cast<std::size_t>(symbol)] != -1) return -1;
        positions[static_cast<std::size_t>(symbol)] = static_cast<std::int16_t>(index);
    }
    for (std::size_t index = 0; index < text_length; ++index) {
        const auto symbol = values[text_length_index + 1 + index];
        if (symbol < 32 || symbol > 126 || positions[static_cast<std::size_t>(symbol)] < 0) return -1;
    }
    if (text_length > output_capacity || (text_length != 0 && output == nullptr)) return -2;

    const auto multiplier = key_a % alphabet_arg;
    const auto inverse = mode == 1 ? inverse_mod(multiplier, alphabet_arg) : 0;
    for (std::size_t index = 0; index < text_length; ++index) {
        const auto symbol = values[text_length_index + 1 + index];
        const auto position = positions[static_cast<std::size_t>(symbol)];
        const auto mapped = mode == 0
            ? (position * multiplier + key_b) % alphabet_arg
            : (((position - key_b + alphabet_arg) % alphabet_arg) * inverse) % alphabet_arg;
        output[index] = static_cast<std::uint8_t>(values[4 + static_cast<std::size_t>(mapped)]);
    }
    return static_cast<std::int64_t>(text_length);
}
