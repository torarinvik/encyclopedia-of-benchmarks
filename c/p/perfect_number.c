/* Check whether n equals the sum of its positive proper divisors. */
#include <stdint.h>

int64_t perfect_number(int64_t n)
{
    if (n <= 1) return 0;
    if (n > INT64_C(1000000000000)) return -1;

    const uint64_t number = (uint64_t)n;
    const uint64_t stride = 1 + (number & 1);
    uint64_t divisor_sum = 1;
    if (stride == 1 && number >= 4) {
        const uint64_t half = number >> 1;
        divisor_sum = half == 2 ? 3 : 3 + half;
    }
    for (uint64_t factor = 3; ; factor += stride) {
        const uint64_t partner = number / factor;
        if (factor > partner) break;
        if (partner * factor == number) {
            divisor_sum += factor;
            if (partner != factor) divisor_sum += partner;
            if (divisor_sum > number) return 0;
        }
    }
    return divisor_sum == number;
}
