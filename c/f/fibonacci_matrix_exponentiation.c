/* Compute one-based Fibonacci values modulo an integer with matrix powers. */
#include <stdint.h>

#define MAX_INDEX UINT64_C(9007199254740991)
#define MAX_MODULUS UINT64_C(4294967295)

static uint64_t multiply_sum(uint64_t a, uint64_t b, uint64_t c, uint64_t d,
                             uint64_t modulus)
{
    return ((a * b) % modulus + (c * d) % modulus) % modulus;
}

double fibonacci_matrix_exponentiation(double index_input, double modulus_input)
{
    if (!(index_input >= 1.0 && index_input <= (double)MAX_INDEX) ||
        !(modulus_input >= 1.0 && modulus_input <= (double)MAX_MODULUS)) return -1.0;
    const uint64_t index = (uint64_t)index_input;
    const uint64_t modulus = (uint64_t)modulus_input;
    if ((double)index != index_input || (double)modulus != modulus_input) return -1.0;

    uint64_t r00 = 1 % modulus, r01 = 0, r10 = 0, r11 = 1 % modulus;
    uint64_t t00 = 0, t01 = 1 % modulus, t10 = 1 % modulus, t11 = 1 % modulus;
    uint64_t exponent = index - 1;
    while (exponent > 0) {
        if (exponent % 2 == 1) {
            const uint64_t n00 = multiply_sum(r00, t00, r01, t10, modulus);
            const uint64_t n01 = multiply_sum(r00, t01, r01, t11, modulus);
            const uint64_t n10 = multiply_sum(r10, t00, r11, t10, modulus);
            const uint64_t n11 = multiply_sum(r10, t01, r11, t11, modulus);
            r00 = n00; r01 = n01; r10 = n10; r11 = n11;
            --exponent;
        } else {
            const uint64_t n00 = multiply_sum(t00, t00, t01, t10, modulus);
            const uint64_t n01 = multiply_sum(t00, t01, t01, t11, modulus);
            const uint64_t n10 = multiply_sum(t10, t00, t11, t10, modulus);
            const uint64_t n11 = multiply_sum(t10, t01, t11, t11, modulus);
            t00 = n00; t01 = n01; t10 = n10; t11 = n11;
            exponent /= 2;
        }
    }
    return (double)((r00 + r10) % modulus);
}
