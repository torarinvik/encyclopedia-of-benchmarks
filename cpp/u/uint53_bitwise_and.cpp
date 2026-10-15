/* Bitwise AND of two nonnegative integers exactly representable by Lua numbers. */
#include <cstdint>

extern "C" std::int64_t uint53_bitwise_and(std::int64_t n, std::int64_t m) noexcept
{
    constexpr std::int64_t max_uint53 = 9007199254740991;
    if (n < 0 || m < 0 || n > max_uint53 || m > max_uint53) return -1;
    std::int64_t result = 0;
    std::int64_t bit = 1;
    while (n != 0 && m != 0) {
        const std::int64_t n_bit = n % 2;
        const std::int64_t m_bit = m % 2;
        result += n_bit * m_bit * bit;
        n = (n - n_bit) / 2;
        m = (m - m_bit) / 2;
        bit *= 2;
    }
    return result;
}
