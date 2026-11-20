// Decide whether the iterated Euler-totient chain sums to n.
#include <cstdint>

namespace {
std::int64_t totient(std::int64_t value) noexcept
{
    auto result = value;
    auto remaining = value;
    for (std::int64_t factor = 2; factor <= remaining / factor; ++factor) {
        if (remaining % factor == 0) {
            do { remaining /= factor; } while (remaining % factor == 0);
            result -= result / factor;
        }
    }
    if (remaining > 1) result -= result / remaining;
    return result;
}
}

extern "C" std::int64_t perfect_totient_number(std::int64_t n) noexcept
{
    if (n < 3 || n > 65535) return -1;
    auto value = n;
    std::int64_t sum = 0;
    while (value > 1) {
        value = totient(value);
        sum += value;
    }
    return sum == n ? 1 : 0;
}
