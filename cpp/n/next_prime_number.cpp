/* Find the smallest prime strictly greater than the input. */
#include <cstdint>

namespace {
bool is_candidate_prime(std::uint32_t value) noexcept
{
    if (value % 3 == 0) return false;
    for (std::uint32_t divisor = 5; divisor * divisor <= value; divisor += 6) {
        if (value % divisor == 0 || value % (divisor + 2) == 0) return false;
    }
    return true;
}
}

extern "C" std::int64_t next_prime_number(std::int64_t value) noexcept
{
    if (value < -4096 || value > 4096) return -1;
    if (value < 2) return 2;
    if (value == 2) return 3;
    std::uint32_t candidate = static_cast<std::uint32_t>(value + 1) | 1;
    while (!is_candidate_prime(candidate)) candidate += 2;
    return candidate;
}
