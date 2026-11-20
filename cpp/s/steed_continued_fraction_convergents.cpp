#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t MODULUS = 998244353;
constexpr std::size_t MAX_INPUT_LENGTH = 19;

std::int64_t mod_pow(std::int64_t base, std::int64_t exponent) noexcept {
    std::int64_t result = 1;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = result * base % MODULUS;
        base = base * base % MODULUS;
        exponent >>= 1;
    }
    return result;
}

bool divisors_are_nonzero(const std::int64_t *input, std::size_t levels) noexcept {
    if (input[2] == 0) return false;
    auto d_value = mod_pow(input[2], MODULUS - 2);
    for (std::size_t level = 2; level <= levels; ++level) {
        const auto denominator =
            (d_value * input[2 * level + 1] + input[2 * level]) % MODULUS;
        if (denominator == 0) return false;
        d_value = mod_pow(denominator, MODULUS - 2);
    }
    return true;
}

void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) noexcept {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 255u);
        bits >>= 8;
    }
}
}

extern "C" std::int64_t steed_continued_fraction_convergents(
    const std::int64_t *input, std::size_t length, std::uint8_t *output,
    std::size_t capacity) noexcept {
    if (input == nullptr || length < 4 || length > MAX_INPUT_LENGTH) return -1;
    const auto levels_value = input[0];
    if (levels_value < 1 || levels_value > 8) return -1;
    const auto levels = static_cast<std::size_t>(levels_value);
    if (length != 2 + 2 * levels) return -1;
    for (std::size_t index = 1; index < length; ++index)
        if (input[index] < 0 || input[index] >= MODULUS) return -1;
    if (!divisors_are_nonzero(input, levels)) return -1;

    const auto required = 8 * (levels + 2);
    if (output == nullptr || capacity < required) return -2;
    store_i64_le(output, 0, levels_value + 1);
    std::int64_t current = input[1];
    store_i64_le(output, 8, current);
    auto d_value = mod_pow(input[2], MODULUS - 2);
    auto delta = input[3] * d_value % MODULUS;
    current = (current + delta) % MODULUS;
    store_i64_le(output, 16, current);
    for (std::size_t level = 2; level <= levels; ++level) {
        const auto b_value = input[2 * level];
        const auto a_value = input[2 * level + 1];
        const auto denominator = (d_value * a_value + b_value) % MODULUS;
        d_value = mod_pow(denominator, MODULUS - 2);
        const auto factor = (b_value * d_value + MODULUS - 1) % MODULUS;
        delta = factor * delta % MODULUS;
        current = (current + delta) % MODULUS;
        store_i64_le(output, 8 * (level + 1), current);
    }
    return static_cast<std::int64_t>(required);
}
