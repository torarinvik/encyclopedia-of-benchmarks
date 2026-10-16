#include <cstdint>

static bool is_prime(std::int64_t value) noexcept
{
    if (value < 2) return false;
    for (std::int64_t factor = 2; factor <= value / factor; ++factor)
        if (value % factor == 0) return false;
    return true;
}

extern "C" std::int64_t problem7(std::int64_t index) noexcept
{
    if (index < 1 || index > 10001) return -1;
    std::int64_t count = 0;
    std::int64_t candidate = 1;
    while (count < index) {
        ++candidate;
        if (is_prime(candidate)) ++count;
    }
    return candidate;
}
