// Count distinct prime divisors with the pinned factor-2 and odd trial loop.
#include <cstdint>

extern "C" std::int64_t hardy_ramanujanalgo(std::int64_t n) noexcept {
    if (n < 1 || n > 2'147'483'647) return -1;

    std::int64_t count = 0;
    if (n % 2 == 0) ++count;
    while (n % 2 == 0) n /= 2;

    for (std::int64_t factor = 3; factor <= n / factor; factor += 2) {
        if (n % factor == 0) {
            ++count;
            while (n % factor == 0) n /= factor;
        }
    }
    if (n > 2) ++count;
    return count;
}
