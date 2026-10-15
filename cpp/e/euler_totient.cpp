// Euler's totient via distinct-prime factorization.
#include <cstdint>

extern "C" std::int64_t euler_totient(std::int64_t n) noexcept {
    if (n < 1 || n > 1000000) return -1;
    std::int64_t result = n;
    std::int64_t remaining = n;
    for (std::int64_t factor = 2; factor <= remaining / factor; ++factor) {
        if (remaining % factor == 0) {
            do { remaining /= factor; } while (remaining % factor == 0);
            result -= result / factor;
        }
    }
    if (remaining > 1) result -= result / remaining;
    return result;
}
