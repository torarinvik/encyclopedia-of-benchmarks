/* Return the source-compatible derangement count for n in 0..=20. */
#include <cstdint>

extern "C" std::int64_t derangement(std::int64_t n) noexcept
{
    if (n < 0 || n > 20) return -1;
    if (n < 2) return 0;
    if (n == 2) return 1;

    std::int64_t previous = 1;
    std::int64_t previous_previous = 0;
    for (std::int64_t i = 3; i <= n; ++i) {
        const std::int64_t current = (i - 1) * (previous + previous_previous);
        previous_previous = previous;
        previous = current;
    }
    return previous;
}
