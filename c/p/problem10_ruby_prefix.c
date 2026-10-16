/* Ruby Project Euler 10's strict cumulative-prime prefix. */
#include <stdint.h>

static int is_prime_value(int64_t number)
{
    if (number > 1 && number < 4) return 1;
    if (number < 2 || number % 2 == 0 || number % 3 == 0) return 0;
    for (int64_t divisor = 5; divisor * divisor <= number; divisor += 6) {
        if (number % divisor == 0 || number % (divisor + 2) == 0) return 0;
    }
    return 1;
}

int64_t problem10_ruby_prefix(int64_t max_total)
{
    if (max_total < 0 || max_total > 2000000) return -1;
    int64_t sum = 1;
    int64_t value = 1;
    for (int64_t number = 2; number < max_total && value < max_total; ++number) {
        if (is_prime_value(number)) {
            value += number;
            if (value < max_total) sum = value;
        }
    }
    return sum;
}
