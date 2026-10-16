/* Bounded port of TheAlgorithms/Python Project Euler 38 search. */
#include <cstdint>

namespace {
bool is_9_pandigital(std::int64_t value) noexcept
{
    if (value < 100000000 || value > 999999999) return false;
    unsigned int mask = 0;
    while (value > 0) {
        const unsigned int digit = static_cast<unsigned int>(value % 10);
        if (digit == 0 || (mask & (1u << digit)) != 0) return false;
        mask |= 1u << digit;
        value /= 10;
    }
    return mask == 0x3feu;
}
}

extern "C" std::int64_t problem38(std::int64_t unused) noexcept
{
    if (unused != 0) return -1;
    for (std::int64_t base = 9999; base > 4999; --base) {
        const std::int64_t candidate = 100002 * base;
        if (is_9_pandigital(candidate)) return candidate;
    }
    for (std::int64_t base = 333; base > 99; --base) {
        const std::int64_t candidate = 1002003 * base;
        if (is_9_pandigital(candidate)) return candidate;
    }
    return -1;
}
