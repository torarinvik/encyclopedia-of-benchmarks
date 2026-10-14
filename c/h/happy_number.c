/* Standard happy-number test: repeatedly sum squared decimal digits. */
#include <stdint.h>

static int64_t digit_square_sum(int64_t n)
{
    int64_t total = 0;
    while (n > 0) {
        int64_t digit = n % 10;
        total += digit * digit;
        n /= 10;
    }
    return total;
}

int64_t happy_number(int64_t n)
{
    if (n <= 0) return -1;
    int64_t slow = digit_square_sum(n);
    int64_t fast = digit_square_sum(digit_square_sum(n));
    while (slow != fast) {
        slow = digit_square_sum(slow);
        fast = digit_square_sum(digit_square_sum(fast));
    }
    return slow == 1 ? 1 : 0;
}
