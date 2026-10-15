// Return whether positive n has no repeated prime factor.
#include <cstdint>

extern "C" std::int64_t is_square_free(std::int64_t n) noexcept
{
    if (n < 1 || n > 1'000'000) return -1;
    for (std::int64_t factor = 2; factor <= n / factor; ++factor) {
        if (n % factor == 0) {
            n /= factor;
            if (n % factor == 0) return 0;
        }
    }
    return 1;
}
