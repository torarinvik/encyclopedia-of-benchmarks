/* Bitwise inclusive OR over the Lua uint53 domain. */
#include <cstdint>

extern "C" std::int64_t uint53_bitwise_or(std::uint64_t left, std::uint64_t right) noexcept
{
    constexpr std::uint64_t max_uint53 = UINT64_C(9007199254740991);
    if (left > max_uint53 || right > max_uint53) return -1;
    std::uint64_t result = 0;
    std::uint64_t bit = 1;
    while (left != 0 && right != 0) {
        const std::uint64_t left_bit = left % 2;
        const std::uint64_t right_bit = right % 2;
        result += (1 - (1 - left_bit) * (1 - right_bit)) * bit;
        left = (left - left_bit) / 2;
        right = (right - right_bit) / 2;
        bit *= 2;
    }
    return static_cast<std::int64_t>(result + (left + right) * bit);
}
