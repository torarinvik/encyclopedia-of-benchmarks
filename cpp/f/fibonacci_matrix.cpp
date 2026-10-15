/* Exact Fibonacci values by binary exponentiation of the Q matrix. */
#include <cstdint>

extern "C" std::int64_t fibonacci_matrix(std::int64_t index) noexcept {
    if (index < 0 || index > 92) return -1;
    if (index == 0) return 0;
    std::int64_t r00 = 1, r01 = 0, r10 = 0, r11 = 1;
    std::int64_t b00 = 1, b01 = 1, b10 = 1, b11 = 0;
    auto exponent = index - 1;
    while (exponent > 0) {
        if (exponent % 2 == 1) {
            const auto n00 = r00 * b00 + r01 * b10;
            const auto n01 = r00 * b01 + r01 * b11;
            const auto n10 = r10 * b00 + r11 * b10;
            const auto n11 = r10 * b01 + r11 * b11;
            r00 = n00; r01 = n01; r10 = n10; r11 = n11;
            --exponent;
        } else {
            const auto n00 = b00 * b00 + b01 * b10;
            const auto n01 = b00 * b01 + b01 * b11;
            const auto n10 = b10 * b00 + b11 * b10;
            const auto n11 = b10 * b01 + b11 * b11;
            b00 = n00; b01 = n01; b10 = n10; b11 = n11;
            exponent /= 2;
        }
    }
    return r00;
}
