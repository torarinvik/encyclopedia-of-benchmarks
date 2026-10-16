#include <cstdint>

static std::int64_t gcd(std::int64_t left, std::int64_t right) noexcept
{
    while (right != 0) {
        const std::int64_t remainder = left % right;
        left = right;
        right = remainder;
    }
    return left;
}

extern "C" std::int64_t problem5(std::int64_t limit) noexcept
{
    if (limit < 1 || limit > 20) return -1;
    std::int64_t result = 1;
    for (std::int64_t value = 2; value <= limit; ++value)
        result = (result / gcd(result, value)) * value;
    return result;
}
