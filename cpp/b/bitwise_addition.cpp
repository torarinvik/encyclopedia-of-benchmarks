/* Add nonnegative integers with XOR and shifted AND carry propagation. */
#include <cstdint>

extern "C" std::int64_t bitwise_addition(std::uint64_t first, std::uint64_t second) noexcept
{
    while (second != 0) {
        const std::uint64_t carry = first & second;
        first ^= second;
        second = carry << 1;
    }
    return static_cast<std::int64_t>(first);
}
