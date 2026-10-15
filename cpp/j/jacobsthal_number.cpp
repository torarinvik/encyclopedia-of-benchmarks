/* Return J(n) for the bounded signed-64-bit Jacobsthal index. */
#include <cstdint>

extern "C" std::int64_t jacobsthal_number(std::int64_t n) noexcept
{
    if (n < 0 || n > 64) return -1;
    if (n == 0) return 0;
    std::int64_t previous = 0;
    std::int64_t current = 1;
    for (std::int64_t index = 2; index <= n; ++index) {
        const std::int64_t next = current + 2 * previous;
        previous = current;
        current = next;
    }
    return current;
}
