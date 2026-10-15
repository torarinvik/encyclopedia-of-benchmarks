// Multiply nonnegative operands with shift-and-add; inputs are at most 1e9.
#include <cstdint>

extern "C" std::int64_t binary_multiplication(std::uint64_t a, std::uint64_t b) noexcept
{
    std::uint64_t result = 0;
    while (b > 0) {
        if ((b & 1U) != 0) {
            result += a;
        }
        a += a;
        b >>= 1;
    }
    return static_cast<std::int64_t>(result);
}
