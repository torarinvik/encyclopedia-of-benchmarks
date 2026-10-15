// Zero-based Tribonacci sequence with source seeds 1, 1, 1.
#include <cstdint>

extern "C" std::int64_t tribonacci_numbers_sequence(std::int64_t index) noexcept
{
    if (index < 0 || index > 60) return -1;
    if (index < 3) return 1;

    std::int64_t first = 1, second = 1, third = 1;
    for (std::int64_t i = 3; i <= index; ++i) {
        const std::int64_t next = first + second + third;
        first = second;
        second = third;
        third = next;
    }
    return third;
}
