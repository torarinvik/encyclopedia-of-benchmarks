/* Return n + 2 when n and n + 2 are twin primes, otherwise -1. */
#include <cstdint>

namespace {
bool is_prime(std::int64_t value) noexcept
{
    if (value < 2) return false;
    if (value == 2) return true;
    if (value % 2 == 0) return false;
    for (std::int64_t divisor = 3; divisor <= value / divisor; divisor += 2) {
        if (value % divisor == 0) return false;
    }
    return true;
}
}

extern "C" std::int64_t twin_prime(std::int64_t value) noexcept
{
    if (value < -4096 || value > 4096) return -1;
    return is_prime(value) && is_prime(value + 2) ? value + 2 : -1;
}
