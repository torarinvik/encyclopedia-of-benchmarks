#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t kMaxDenominator = 1'000'000;
constexpr std::int64_t kMaxCfSum = 60;

void store_i64_le(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 255U);
        bits >>= 8;
    }
}

std::int64_t partial_quotient_sum(std::int64_t numerator, std::int64_t denominator) {
    std::int64_t total = 0;
    while (numerator != 0) {
        const auto quotient = denominator / numerator;
        if (quotient > kMaxCfSum - total) return -1;
        total += quotient;
        const auto remainder = denominator % numerator;
        denominator = numerator;
        numerator = remainder;
    }
    return total;
}

std::int64_t alternating_dyadic_numerator(std::int64_t numerator,
                                          std::int64_t denominator,
                                          std::int64_t total) {
    std::int64_t result = 0, prefix = 0, index = 1;
    while (numerator != 0) {
        const auto quotient = denominator / numerator;
        prefix += quotient;
        const auto term = std::int64_t{1} << (total - prefix);
        result += (index & 1) ? term : -term;
        const auto remainder = denominator % numerator;
        denominator = numerator;
        numerator = remainder;
        ++index;
    }
    return result;
}
}

extern "C" std::int64_t minkowski_question_mark_rational(
    const std::int64_t* input, std::size_t length,
    std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || length < 1 || length > 3) return -1;
    if (length != 2) return -1;
    const auto p = input[0];
    const auto q = input[1];
    if (p < 0 || q < 1 || q > kMaxDenominator || p > q) return -1;
    const auto total = partial_quotient_sum(p, q);
    if (total < 0) return -1;
    if (output == nullptr || capacity < 16) return -2;

    const auto value = alternating_dyadic_numerator(p, q, total);
    const auto exponent = total == 0 ? 0 : total - 1;
    store_i64_le(output, 0, value);
    store_i64_le(output, 8, exponent);
    return 16;
}
