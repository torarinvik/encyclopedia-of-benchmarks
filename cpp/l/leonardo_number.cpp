/* Iteratively compute L(0)=L(1)=1 and L(n)=L(n-1)+L(n-2)+1. */
#include <cstdint>

extern "C" std::int64_t leonardo_number(std::int64_t input) noexcept
{
    if (input < 0 || input > 89) return -1;
    std::int64_t previous = 1;
    std::int64_t current = 1;
    for (std::int64_t index = 2; index <= input; ++index) {
        const auto next = current + previous + 1;
        previous = current;
        current = next;
    }
    return current;
}
