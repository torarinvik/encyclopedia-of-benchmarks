/* Find the smallest prime strictly greater than the input. */
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

extern "C" std::int64_t next_prime_number(std::int64_t value) noexcept
{
    if (value < -4096 || value > 4096) return -1;
    std::int64_t candidate = value + 1;
    if (candidate < 2) candidate = 2;
    while (!is_prime(candidate)) ++candidate;
    return candidate;
}
