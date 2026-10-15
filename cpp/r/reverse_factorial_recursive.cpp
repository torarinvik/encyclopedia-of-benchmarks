#include <cstdint>

namespace {
std::int64_t reverse_factorial_recursive_impl(std::int64_t value, std::int64_t divisor)
{
    if (value == 1) return divisor == 1 ? 1 : divisor - 1;
    if (value % divisor != 0) return -1;
    return reverse_factorial_recursive_impl(value / divisor, divisor + 1);
}
}

extern "C" std::int64_t reverse_factorial_recursive(std::int64_t value) noexcept
{
    if (value < 1) return -1;
    return reverse_factorial_recursive_impl(value, 1);
}
