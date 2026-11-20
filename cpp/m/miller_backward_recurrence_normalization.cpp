#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t MODULUS = 998244353;
constexpr std::size_t MAX_INPUT_LENGTH = 35;

std::int64_t mod_pow(std::int64_t base, std::int64_t exponent) noexcept {
    std::int64_t result = 1;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = result * base % MODULUS;
        base = base * base % MODULUS;
        exponent >>= 1;
    }
    return result;
}

std::int64_t difference(std::int64_t left, std::int64_t right) noexcept {
    return (left + MODULUS - right) % MODULUS;
}

void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) noexcept {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 255u);
        bits >>= 8;
    }
}
}

extern "C" std::int64_t miller_backward_recurrence_normalization(
    const std::int64_t *input, std::size_t length, std::uint8_t *output,
    std::size_t capacity) noexcept {
    if (input == nullptr || length < 6 || length > MAX_INPUT_LENGTH) return -1;
    const auto levels_value = input[0];
    if (levels_value < 1 || levels_value > 8) return -1;
    const auto levels = static_cast<std::size_t>(levels_value);
    if (length != 4 * levels + 2) return -1;
    for (std::size_t index = 1; index < length; ++index)
        if (input[index] < 0 || input[index] >= MODULUS) return -1;
    for (std::size_t level = 1; level <= levels; ++level)
        if (input[3 * level] == 0) return -1;

    std::int64_t trial[10] = {};
    trial[levels] = 1;
    trial[levels + 1] = 0;
    for (std::size_t level = levels; level > 0; --level) {
        const auto a_value = input[3 * level - 2];
        const auto b_value = input[3 * level - 1];
        const auto c_value = input[3 * level];
        const auto positive = b_value * trial[level] % MODULUS;
        const auto negative = a_value * trial[level + 1] % MODULUS;
        trial[level - 1] = difference(positive, negative) * mod_pow(c_value, MODULUS - 2) % MODULUS;
    }
    const auto lambda_start = 3 * levels + 1;
    std::int64_t normalizer = 0;
    for (std::size_t index = 0; index <= levels; ++index)
        normalizer = (normalizer + input[lambda_start + index] * trial[index]) % MODULUS;
    if (normalizer == 0) return -1;
    const auto scale = mod_pow(normalizer, MODULUS - 2);
    const auto required = 8 * (levels + 2);
    if (output == nullptr || capacity < required) return -2;

    store_i64_le(output, 0, levels_value);
    for (std::size_t index = 0; index <= levels; ++index)
        store_i64_le(output, 8 * (index + 1), trial[index] * scale % MODULUS);
    return static_cast<std::int64_t>(required);
}
