/* Standard happy-number test: repeatedly sum squared decimal digits. */
#include <cstdint>

namespace {
std::int64_t digit_square_sum(std::int64_t n)
{
    std::int64_t total = 0;
    while (n > 0) {
        const std::int64_t digit = n % 10;
        total += digit * digit;
        n /= 10;
    }
    return total;
}
}

extern "C" std::int64_t happy_number(std::int64_t n) noexcept
{
    if (n <= 0) return -1;
    std::int64_t slow = digit_square_sum(n);
    std::int64_t fast = digit_square_sum(digit_square_sum(n));
    while (slow != fast) {
        slow = digit_square_sum(slow);
        fast = digit_square_sum(digit_square_sum(fast));
    }
    return slow == 1 ? 1 : 0;
}
