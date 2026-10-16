#include <cstdint>

// Return the sum of all positive divisors of n by prime factorization.
extern "C" std::int64_t sum_of_divisors(std::int64_t n) noexcept
{
    if (n < 1 || n > 1000000) return -1;
    std::int64_t remaining = n;
    std::int64_t sigma = 1;
    for (std::int64_t factor = 2; factor <= remaining / factor; ++factor) {
        if (remaining % factor == 0) {
            std::int64_t power = 1;
            std::int64_t geometric_sum = 1;
            do {
                remaining /= factor;
                power *= factor;
                geometric_sum += power;
            } while (remaining % factor == 0);
            sigma *= geometric_sum;
        }
    }
    if (remaining > 1) sigma *= remaining + 1;
    return sigma;
}
