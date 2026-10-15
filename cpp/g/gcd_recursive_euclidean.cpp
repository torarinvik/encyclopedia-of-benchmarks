/* Recursive subtraction-based Euclidean GCD on a bounded positive domain. */
#include <cstdint>

static std::int64_t gcd_recursive_euclidean_step(std::uint64_t left, std::uint64_t right) noexcept
{
    if (left == right) {
        return static_cast<std::int64_t>(left);
    }
    if (left > right) {
        return gcd_recursive_euclidean_step(left - right, right);
    }
    return gcd_recursive_euclidean_step(left, right - left);
}

extern "C" std::int64_t gcd_recursive_euclidean(std::uint64_t left, std::uint64_t right) noexcept
{
    if (left == 0 || right == 0 || left > 128 || right > 128) {
        return -1;
    }
    return gcd_recursive_euclidean_step(left, right);
}
