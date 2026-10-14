/* Portable iterative Euclidean GCD for nonnegative signed 64-bit inputs. */
#include <cstdint>

extern "C" std::int64_t gcd(std::uint64_t left, std::uint64_t right) noexcept
{
    while (right != 0) {
        const auto remainder = left % right;
        left = right;
        right = remainder;
    }
    return static_cast<std::int64_t>(left);
}
