/* Independent portable implementation; upstream references are in the guide. */
#include <cstdint>
#include <limits>

extern "C" std::int64_t aliquot_sum(std::int64_t n) noexcept
{
    if (n < 0) return -1;
    std::int64_t sum = 0;
    for (std::int64_t divisor = 1; divisor <= n / 2; ++divisor) {
        if (n % divisor == 0) {
            if (sum > std::numeric_limits<std::int64_t>::max() - divisor) return -1;
            sum += divisor;
        }
    }
    return sum;
}
