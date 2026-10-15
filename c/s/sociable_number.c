/* Exact-cycle sociable-number check adapted from the pinned Java source. */
#include <stdint.h>

static uint64_t sociable_sum_proper_divisors(uint64_t number)
{
    if (number <= 1) return 0;
    uint64_t sum = 1;
    for (uint64_t divisor = 2; divisor <= number / divisor; ++divisor) {
        if (number % divisor == 0) {
            uint64_t other = number / divisor;
            sum += divisor;
            if (other != divisor) sum += other;
        }
    }
    return sum;
}

int64_t sociable_number(uint64_t number, uint64_t cycle_length)
{
    if (number == 0 || number > 100000 || cycle_length < 2 || cycle_length > 3) return -1;
    uint64_t current = number;
    for (uint64_t step = 0; step < cycle_length; ++step) {
        current = sociable_sum_proper_divisors(current);
        if (current == number) return step == cycle_length - 1 ? 1 : 0;
    }
    return 0;
}
