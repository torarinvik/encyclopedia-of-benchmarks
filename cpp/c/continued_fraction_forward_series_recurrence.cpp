#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t MODULUS = 998244353;
constexpr std::size_t MAX_INPUT_LENGTH = 11;

std::int64_t mod_pow(std::int64_t base, std::int64_t exponent) noexcept {
    std::int64_t result = 1;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = result * base % MODULUS;
        base = base * base % MODULUS;
        exponent >>= 1;
    }
    return result;
}

std::int64_t advance_numerator(std::int64_t coefficient, std::int64_t rho) noexcept {
    return coefficient * ((rho + 1) % MODULUS) % MODULUS;
}

bool divisors_are_nonzero(const std::int64_t *input, std::size_t count) noexcept {
    std::int64_t rho = 0;
    for (std::size_t index = 1; index < count; ++index) {
        const auto numerator = advance_numerator(input[index + 1], rho);
        const auto denominator = (1 + MODULUS - numerator) % MODULUS;
        if (denominator == 0) return false;
        rho = numerator * mod_pow(denominator, MODULUS - 2) % MODULUS;
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

extern "C" std::int64_t continued_fraction_forward_series_recurrence(
    const std::int64_t *input, std::size_t length, std::uint8_t *output,
    std::size_t capacity) noexcept {
    if (input == nullptr || length < 3 || length > MAX_INPUT_LENGTH) return -1;
    const auto count_value = input[0];
    if (count_value < 2 || count_value > 9) return -1;
    const auto count = static_cast<std::size_t>(count_value);
    if (length != count + 1) return -1;
    for (std::size_t index = 1; index <= count; ++index)
        if (input[index] < 0 || input[index] >= MODULUS) return -1;
    if (!divisors_are_nonzero(input, count)) return -1;

    const auto required = 8 * (count + 1);
    if (output == nullptr || capacity < required) return -2;
    store_i64_le(output, 0, count_value);
    std::int64_t rho = 0;
    std::int64_t term = input[1];
    std::int64_t sum = term;
    store_i64_le(output, 8, sum);
    for (std::size_t index = 1; index < count; ++index) {
        const auto numerator = advance_numerator(input[index + 1], rho);
        const auto denominator = (1 + MODULUS - numerator) % MODULUS;
        rho = numerator * mod_pow(denominator, MODULUS - 2) % MODULUS;
        term = rho * term % MODULUS;
        sum = (sum + term) % MODULUS;
        store_i64_le(output, 8 * (index + 1), sum);
    }
    return static_cast<std::int64_t>(required);
}
