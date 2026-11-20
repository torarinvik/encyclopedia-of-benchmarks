#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t max_n = 22;
constexpr std::size_t max_parseable_length = 2;

std::int64_t gcd_positive(std::int64_t left, std::int64_t right) {
    while (right != 0) {
        const std::int64_t remainder = left % right;
        left = right;
        right = remainder;
    }
    return left;
}

std::int64_t accumulate_harmonic_numerator(std::int64_t n) {
    std::int64_t top = 0;
    std::int64_t bottom = 1;
    for (std::int64_t term = 1; term <= n; ++term) {
        const std::int64_t denominator_term = term * term;
        const std::int64_t shared = gcd_positive(bottom, denominator_term);
        const std::int64_t multiplier = denominator_term / shared;
        top = top * multiplier + bottom / shared;
        bottom *= multiplier;
        const std::int64_t common_factor = gcd_positive(top, bottom);
        top /= common_factor;
        bottom /= common_factor;
    }
    return top;
}
}

extern "C" std::int64_t wolstenholme_numbers(const std::int64_t *input, std::size_t length) {
    if (input == nullptr || length < 1 || length > max_parseable_length) return -1;
    if (length != 1 || input[0] < 1 || input[0] > max_n) return -1;
    return accumulate_harmonic_numerator(input[0]);
}
