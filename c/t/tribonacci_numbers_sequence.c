/* Zero-based Tribonacci sequence with source seeds 1, 1, 1. */
#include <stdint.h>

int64_t tribonacci_numbers_sequence(int64_t index)
{
    if (index < 0 || index > 60) return -1;
    if (index < 3) return 1;

    int64_t first = 1, second = 1, third = 1;
    for (int64_t i = 3; i <= index; ++i) {
        const int64_t next = first + second + third;
        first = second;
        second = third;
        third = next;
    }
    return third;
}
