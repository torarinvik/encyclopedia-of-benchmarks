/* Complement only the significant binary digits of a nonnegative integer. */
#include <cstdint>

extern "C" std::int64_t bitwise_complement(std::int64_t n) noexcept
{
    if (n < 0 || n > 999999999) return -1;
    if (n == 0) return 1;
    auto value = static_cast<std::uint64_t>(n);
    std::uint64_t mask = 0;
    while (value != 0) {
        mask = (mask << 1) | UINT64_C(1);
        value >>= 1;
    }
    return n ^ static_cast<std::int64_t>(mask);
}
