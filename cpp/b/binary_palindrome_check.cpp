/* Test whether the significant binary digits of an int32 value form a palindrome. */
#include <cstdint>
#include <limits>

extern "C" std::int64_t binary_palindrome_check(std::int64_t number) noexcept
{
    if (number < std::numeric_limits<std::int32_t>::min() ||
        number > std::numeric_limits<std::int32_t>::max()) return -1;
    if (number < 0) return 0;
    auto remaining = number;
    std::int64_t reversed = 0;
    while (remaining > 0) {
        reversed = (reversed << 1) | (remaining & 1);
        remaining >>= 1;
    }
    return reversed == number ? 1 : 0;
}
