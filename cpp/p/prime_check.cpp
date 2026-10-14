/* Trial-division primality check over the shared bounded integer domain. */
#include <cstdint>

extern "C" std::int64_t prime_check(std::int64_t n) noexcept
{
    if (n < 2) return 0;
    if (n > INT32_MAX) return -1;
    if (n % 2 == 0) return n == 2 ? 1 : 0;
    for (std::int64_t factor = 3; factor <= n / factor; factor += 2) {
        if (n % factor == 0) return 0;
    }
    return 1;
}
