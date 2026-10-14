/* Check whether n equals the sum of its positive proper divisors. */
#include <cstdint>

extern "C" std::int64_t perfect_number(std::int64_t n) noexcept
{
    if (n <= 1) return 0;
    if (n > INT64_C(1000000000000)) return -1;

    std::int64_t divisor_sum = 1;
    for (std::int64_t factor = 2; factor <= n / factor; ++factor) {
        if (n % factor == 0) {
            divisor_sum += factor;
            const std::int64_t partner = n / factor;
            if (partner != factor) divisor_sum += partner;
            if (divisor_sum > n) return 0;
        }
    }
    return divisor_sum == n;
}
