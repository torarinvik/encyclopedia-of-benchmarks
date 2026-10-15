/* Compute one-based Fibonacci values modulo an integer with matrix powers. */
#include <cstdint>

namespace {
constexpr std::uint64_t max_index = UINT64_C(9007199254740991);
constexpr std::uint64_t max_modulus = UINT64_C(4294967295);

std::uint64_t multiply_sum(std::uint64_t a, std::uint64_t b, std::uint64_t c,
                           std::uint64_t d, std::uint64_t modulus) noexcept {
    return ((a * b) % modulus + (c * d) % modulus) % modulus;
}
}

extern "C" double fibonacci_matrix_exponentiation(double index_input,
                                                    double modulus_input) noexcept {
    if (!(index_input >= 1.0 && index_input <= static_cast<double>(max_index)) ||
        !(modulus_input >= 1.0 && modulus_input <= static_cast<double>(max_modulus))) return -1.0;
    const auto index = static_cast<std::uint64_t>(index_input);
    const auto modulus = static_cast<std::uint64_t>(modulus_input);
    if (static_cast<double>(index) != index_input || static_cast<double>(modulus) != modulus_input)
        return -1.0;

    std::uint64_t r00 = 1 % modulus, r01 = 0, r10 = 0, r11 = 1 % modulus;
    std::uint64_t t00 = 0, t01 = 1 % modulus, t10 = 1 % modulus, t11 = 1 % modulus;
    auto exponent = index - 1;
    while (exponent > 0) {
        if (exponent % 2 == 1) {
            const auto n00 = multiply_sum(r00, t00, r01, t10, modulus);
            const auto n01 = multiply_sum(r00, t01, r01, t11, modulus);
            const auto n10 = multiply_sum(r10, t00, r11, t10, modulus);
            const auto n11 = multiply_sum(r10, t01, r11, t11, modulus);
            r00 = n00; r01 = n01; r10 = n10; r11 = n11;
            --exponent;
        } else {
            const auto n00 = multiply_sum(t00, t00, t01, t10, modulus);
            const auto n01 = multiply_sum(t00, t01, t01, t11, modulus);
            const auto n10 = multiply_sum(t10, t00, t11, t10, modulus);
            const auto n11 = multiply_sum(t10, t01, t11, t11, modulus);
            t00 = n00; t01 = n01; t10 = n10; t11 = n11;
            exponent /= 2;
        }
    }
    return static_cast<double>((r00 + r10) % modulus);
}
