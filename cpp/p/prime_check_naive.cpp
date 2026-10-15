// Unoptimized trial division under a bounded positive input contract.
#include <cstdint>

extern "C" std::int64_t prime_check_naive(std::int64_t n) noexcept {
    if (n > 10000) return -1;
    if (n < 2) return 0;
    for (std::int64_t divisor = 2; divisor < n; ++divisor) {
        if (n % divisor == 0) return 0;
    }
    return 1;
}
