#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_parseable_length = 2;
constexpr std::int64_t max_n = INT64_C(1000000000000);

std::int64_t derivative_from_factors(std::int64_t n) noexcept {
    if (n < 2) return 0;
    const auto original = n;
    std::int64_t derivative = 0;
    std::int64_t factor = 2;
    while (factor <= n / factor) {
        if (n % factor == 0) {
            std::int64_t exponent = 0;
            do {
                n /= factor;
                ++exponent;
            } while (n % factor == 0);
            derivative += (original / factor) * exponent;
        }
        factor = factor == 2 ? 3 : factor + 2;
    }
    if (n > 1) derivative += original / n;
    return derivative;
}
}

extern "C" std::int64_t arithmetic_derivative(const std::int64_t* input,
                                                 std::size_t length) noexcept {
    if (input == nullptr || length < 1 || length > max_parseable_length) return -1;
    if (length != 1) return -1;
    const auto n = input[0];
    if (n < 0 || n > max_n) return -1;
    return derivative_from_factors(n);
}
