/* Maximum exponent of a composite k dividing n!, via prime valuations. */
#include <stdint.h>

#define FDCK_MAX_N UINT64_C(1000000000000)
#define FDCK_MAX_K UINT64_C(1000000)

static uint64_t fdck_valuation(uint64_t n, uint64_t prime)
{
    uint64_t total = 0;
    while (n != 0) {
        n /= prime;
        total += n;
    }
    return total;
}

int64_t factorial_divisor_composite_k(uint64_t n, uint64_t k)
{
    if (n > FDCK_MAX_N || k < 4 || k > FDCK_MAX_K) return -1;

    uint64_t remaining = k;
    uint64_t divisor = 2;
    uint64_t answer = n;
    int composite = 0;
    while (divisor <= remaining / divisor) {
        if (remaining % divisor == 0) {
            composite = 1;
            uint64_t exponent = 0;
            do {
                remaining /= divisor;
                ++exponent;
            } while (remaining % divisor == 0);
            uint64_t candidate = fdck_valuation(n, divisor) / exponent;
            if (candidate < answer) answer = candidate;
        }
        ++divisor;
    }

    if (!composite) return -1;
    if (remaining > 1) {
        uint64_t candidate = fdck_valuation(n, remaining);
        if (candidate < answer) answer = candidate;
    }
    return (int64_t)answer;
}
