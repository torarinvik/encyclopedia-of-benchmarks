// Convert a nonnegative integer to its binary-reflected Gray code.
#include <cstdint>

extern "C" std::int64_t binary_to_gray_code(std::int64_t value) noexcept
{
    if (value < 0) return -1;
    return value ^ (value >> 1);
}
