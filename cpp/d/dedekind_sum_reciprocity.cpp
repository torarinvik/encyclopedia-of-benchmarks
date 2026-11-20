#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t max_modulus = 100'000;
constexpr std::size_t max_length = 3;
constexpr std::int64_t result_offset = 29'999'700'001;

std::int64_t gcd(std::int64_t left, std::int64_t right) {
    while (right != 0) {
        const auto remainder = left % right;
        left = right;
        right = remainder;
    }
    return left;
}

std::int64_t scaled_sum(std::int64_t numerator, std::int64_t modulus) {
    if (modulus == 1) return 0;
    const auto tail = scaled_sum(modulus % numerator, numerator);
    const auto top = numerator * numerator + modulus * modulus + 1 -
                     3 * numerator * modulus - modulus * tail;
    return top / numerator;
}
}

extern "C" std::int64_t dedekind_sum_reciprocity(const std::int64_t* input,
                                                  std::size_t length) {
    if (input == nullptr || length < 2 || length > max_length) return -1;
    const auto numerator = input[0];
    const auto modulus = input[1];
    if (length != 2 || modulus < 1 || modulus > max_modulus ||
        numerator < 0 || numerator >= modulus || gcd(numerator, modulus) != 1)
        return -1;
    return result_offset + scaled_sum(numerator, modulus);
}
