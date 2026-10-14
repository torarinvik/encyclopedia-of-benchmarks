/* Portable LCM with overflow checked after dividing by the GCD. */
#include <cstdint>
#include <limits>

extern "C" std::int64_t lcm(std::uint64_t left, std::uint64_t right) noexcept
{
    if (left == 0 || right == 0) return 0;
    auto a = left, b = right;
    while (b != 0) {
        const auto remainder = a % b;
        a = b;
        b = remainder;
    }
    const auto reduced = left / a;
    const auto max_result = static_cast<std::uint64_t>(std::numeric_limits<std::int64_t>::max());
    if (reduced > max_result / right) return -1;
    return static_cast<std::int64_t>(reduced * right);
}
