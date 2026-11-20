// Maximum exponent of a composite k dividing n!, via prime valuations.
#include <cstdint>

static uint64_t factorial_divisor_composite_k_valuation(uint64_t n, uint64_t prime)
{
    uint64_t total = 0;
    while (n != 0) {
        n /= prime;
        total += n;
    }
    return total;
}

extern "C" int64_t factorial_divisor_composite_k(uint64_t n, uint64_t k)
{
    if (n > UINT64_C(1000000000000) || k < 4 || k > 1000000) return -1;

    uint64_t remaining = k;
    uint64_t divisor = 2;
    uint64_t answer = n;
    bool composite = false;
    while (divisor <= remaining / divisor) {
        if (remaining % divisor == 0) {
            composite = true;
            uint64_t exponent = 0;
            do {
                remaining /= divisor;
                ++exponent;
            } while (remaining % divisor == 0);
            const uint64_t candidate =
                factorial_divisor_composite_k_valuation(n, divisor) / exponent;
            if (candidate < answer) answer = candidate;
        }
        ++divisor;
    }

    if (!composite) return -1;
    if (remaining > 1) {
        const uint64_t candidate = factorial_divisor_composite_k_valuation(n, remaining);
        if (candidate < answer) answer = candidate;
    }
    return static_cast<int64_t>(answer);
}
