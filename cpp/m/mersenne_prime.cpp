#include <cstdint>

static bool is_prime_i64(std::int64_t n) {
    if (n < 2) return false;
    if (n % 2 == 0) return n == 2;
    for (std::int64_t factor = 3; factor <= n / factor; factor += 2) {
        if (n % factor == 0) return false;
    }
    return true;
}

extern "C" std::int64_t mersenne_prime(std::int64_t n) {
    if (n == 0) return 0;
    if (n < 0 || n > 2147483647) return -1;
    std::int64_t remaining = n + 1;
    while (remaining % 2 == 0) remaining /= 2;
    if (remaining != 1) return 0;
    return is_prime_i64(n) ? 1 : 0;
}
