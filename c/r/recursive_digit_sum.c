/* Compute the source's repeated-digit-sum result from n and k. */
#include <stdint.h>

int64_t recursive_digit_sum(int64_t number, int64_t repetitions)
{
    if (number < 0 || repetitions < 0 || repetitions > 1000000) return -1;
    int64_t digit_sum = 0;
    do {
        digit_sum += number % 10;
        number /= 10;
    } while (number != 0);
    int64_t total = digit_sum * repetitions;
    while (total >= 10) {
        int64_t next = 0;
        do {
            next += total % 10;
            total /= 10;
        } while (total != 0);
        total = next;
    }
    return total;
}
