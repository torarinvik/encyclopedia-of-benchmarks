#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t max_modulus = 1'000'000'000;
constexpr std::size_t max_length = 3;

std::int64_t reciprocity(std::int64_t numerator, std::int64_t denominator) {
    std::int64_t sign = 1;
    while (numerator != 0) {
        while ((numerator & 1) == 0) {
            numerator /= 2;
            if (denominator % 8 == 3 || denominator % 8 == 5) sign = -sign;
        }
        if (numerator % 4 == 3 && denominator % 4 == 3) sign = -sign;
        const auto old_numerator = numerator;
        numerator = denominator;
        denominator = old_numerator;
        numerator %= denominator;
    }
    return denominator == 1 ? sign : 0;
}
}

extern "C" std::int64_t jacobi_symbol(const std::int64_t* input, std::size_t length) {
    if (input == nullptr || length < 2 || length > max_length) return -1;
    const auto numerator = input[0];
    const auto denominator = input[1];
    if (denominator < 1 || denominator > max_modulus || (denominator & 1) == 0 ||
        numerator < 0 || numerator >= denominator || length != 2) return -1;
    return reciprocity(numerator, denominator) + 1;
}
