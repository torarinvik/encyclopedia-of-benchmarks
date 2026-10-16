/* Count sqrt(2) convergents whose numerator has more decimal digits. */
#include <stdint.h>

#define MAX_ITERATIONS 10000
#define MAX_LIMBS 512
#define LIMB_BASE UINT64_C(1000000000)

static int decimal_digits(uint64_t value)
{
    int digits = 1;
    while (value >= 10) { value /= 10; ++digits; }
    return digits;
}

int64_t problem57(int64_t iterations)
{
    if (iterations <= 0) return 0;
    if (iterations > MAX_ITERATIONS) return -1;
    uint64_t numerator[MAX_LIMBS] = {1};
    uint64_t denominator[MAX_LIMBS] = {1};
    uint64_t next_numerator[MAX_LIMBS] = {0};
    uint64_t next_denominator[MAX_LIMBS] = {0};
    int numerator_length = 1, denominator_length = 1;
    int64_t result = 0;
    for (int64_t iteration = 0; iteration < iterations; ++iteration) {
        const int shared_length = numerator_length > denominator_length
            ? numerator_length : denominator_length;
        uint64_t numerator_carry = 0, denominator_carry = 0;
        for (int index = 0; index < shared_length; ++index) {
            const uint64_t n_digit = index < numerator_length ? numerator[index] : 0;
            const uint64_t d_digit = index < denominator_length ? denominator[index] : 0;
            const uint64_t n_sum = n_digit + 2 * d_digit + numerator_carry;
            const uint64_t d_sum = n_digit + d_digit + denominator_carry;
            next_numerator[index] = n_sum % LIMB_BASE;
            next_denominator[index] = d_sum % LIMB_BASE;
            numerator_carry = n_sum / LIMB_BASE;
            denominator_carry = d_sum / LIMB_BASE;
        }
        int next_numerator_length = shared_length;
        int next_denominator_length = shared_length;
        while (numerator_carry > 0) {
            if (next_numerator_length >= MAX_LIMBS) return -1;
            next_numerator[next_numerator_length++] = numerator_carry % LIMB_BASE;
            numerator_carry /= LIMB_BASE;
        }
        while (denominator_carry > 0) {
            if (next_denominator_length >= MAX_LIMBS) return -1;
            next_denominator[next_denominator_length++] = denominator_carry % LIMB_BASE;
            denominator_carry /= LIMB_BASE;
        }
        const int numerator_digits = (next_numerator_length - 1) * 9 +
                                     decimal_digits(next_numerator[next_numerator_length - 1]);
        const int denominator_digits = (next_denominator_length - 1) * 9 +
                                       decimal_digits(next_denominator[next_denominator_length - 1]);
        if (numerator_digits > denominator_digits) ++result;
        for (int index = 0; index < next_numerator_length; ++index)
            numerator[index] = next_numerator[index];
        for (int index = 0; index < next_denominator_length; ++index)
            denominator[index] = next_denominator[index];
        numerator_length = next_numerator_length;
        denominator_length = next_denominator_length;
    }
    return result;
}
