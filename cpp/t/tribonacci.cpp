/* Portable zero-based Tribonacci recurrence for the shared i64 contract. */
#include <cstdint>

extern "C" std::int64_t tribonacci(std::int64_t n) noexcept
{
    if (n < 0 || n > 73) return -1;
    if (n == 0) return 0;
    if (n <= 2) return 1;
    std::int64_t previous_three = 0, previous_two = 1, previous_one = 1;
    for (std::int64_t index = 3; index <= n; ++index) {
        const std::int64_t next = previous_three + previous_two + previous_one;
        previous_three = previous_two;
        previous_two = previous_one;
        previous_one = next;
    }
    return previous_one;
}
