/* Return the Möbius function for a bounded positive integer. */
#include <cstdint>

extern "C" std::int64_t mobius_function(std::int64_t n) noexcept
{
    if (n < 1 || n > 10000) return INT64_MIN;
    std::int64_t remaining = n;
    std::int64_t distinct_factor_count = 0;
    for (std::int64_t factor = 2; factor * factor <= remaining; ++factor) {
        if (remaining % factor == 0) {
            remaining /= factor;
            if (remaining % factor == 0) return 0;
            ++distinct_factor_count;
        }
    }
    if (remaining > 1) ++distinct_factor_count;
    return distinct_factor_count % 2 == 0 ? 1 : -1;
}
