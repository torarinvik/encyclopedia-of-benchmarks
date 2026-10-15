/* Exact Fibonacci values by binary exponentiation of the Q matrix. */
#include <stdint.h>

int64_t fibonacci_matrix(int64_t index)
{
    if (index < 0 || index > 92) return -1;
    if (index == 0) return 0;
    int64_t r00 = 1, r01 = 0, r10 = 0, r11 = 1;
    int64_t b00 = 1, b01 = 1, b10 = 1, b11 = 0;
    int64_t exponent = index - 1;
    while (exponent > 0) {
        if (exponent % 2 == 1) {
            const int64_t n00 = r00 * b00 + r01 * b10;
            const int64_t n01 = r00 * b01 + r01 * b11;
            const int64_t n10 = r10 * b00 + r11 * b10;
            const int64_t n11 = r10 * b01 + r11 * b11;
            r00 = n00; r01 = n01; r10 = n10; r11 = n11;
            --exponent;
        } else {
            const int64_t n00 = b00 * b00 + b01 * b10;
            const int64_t n01 = b00 * b01 + b01 * b11;
            const int64_t n10 = b10 * b00 + b11 * b10;
            const int64_t n11 = b10 * b01 + b11 * b11;
            b00 = n00; b01 = n01; b10 = n10; b11 = n11;
            exponent /= 2;
        }
    }
    return r00;
}
