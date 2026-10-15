/* Count multiples of divisor in the inclusive positive integer interval [first, last]. */
#include <stdint.h>

double count_numbers_divisible(double first, double last, double divisor)
{
    const int64_t a = (int64_t)first;
    const int64_t b = (int64_t)last;
    const int64_t m = (int64_t)divisor;
    return (double)(b / m - (a - 1) / m);
}
