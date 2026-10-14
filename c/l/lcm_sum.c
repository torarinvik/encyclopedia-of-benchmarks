/* Sum LCM(i, n), 1 <= i <= n, using the Euler-totient identity. */
#include <stdint.h>

static uint64_t euler_phi(uint64_t value)
{
    uint64_t result = value;
    uint64_t remaining = value;
    for (uint64_t factor = 2; factor <= remaining / factor; factor += factor == 2 ? 1 : 2) {
        if (remaining % factor == 0) {
            result -= result / factor;
            do { remaining /= factor; } while (remaining % factor == 0);
        }
    }
    if (remaining > 1) result -= result / remaining;
    return result;
}

int64_t lcm_sum(int64_t input)
{
    if (input < 1 || input > 65535) return -1;
    const uint64_t n = (uint64_t)input;
    uint64_t weighted_totients = 1;
    for (uint64_t divisor = 1; divisor <= n / divisor; ++divisor) {
        if (n % divisor == 0) {
            weighted_totients += divisor * euler_phi(divisor);
            const uint64_t paired = n / divisor;
            if (paired != divisor) weighted_totients += paired * euler_phi(paired);
        }
    }
    return (int64_t)((weighted_totients * n) / 2);
}
