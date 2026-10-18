/* Greatest prime factor over the bounded primelib input domain. */
#include <cstdint>

static bool is_prime_trial(std::int64_t value) noexcept
{
    if (value < 2) return false;
    for (std::int64_t divisor = 2; divisor <= value / divisor; ++divisor) {
        if (value % divisor == 0) return false;
    }
    return true;
}

extern "C" std::int64_t greatest_prime_factor(std::int64_t n) noexcept
{
    if (n < 0 || n > 1000000) return -1;
    if (n < 2) return n;
    if (is_prime_trial(n)) return n;

    std::int64_t quotient = n;
    std::int64_t largest = 0;
    std::int64_t factor = 2;
    while (quotient != 1) {
        if (is_prime_trial(factor) && quotient % factor == 0) {
            largest = factor;
            quotient /= factor;
        } else {
            ++factor;
        }
    }
    return largest;
}
