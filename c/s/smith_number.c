#include <stdint.h>

static int is_prime(int64_t value)
{
    if (value == 2) return 1;
    if (value < 2 || value % 2 == 0) return 0;
    for (int64_t divisor = 3; divisor <= value / divisor; divisor += 2) {
        if (value % divisor == 0) return 0;
    }
    return 1;
}

static int64_t digit_sum(int64_t value)
{
    int64_t sum = 0;
    while (value != 0) {
        sum += value % 10;
        value /= 10;
    }
    return sum;
}

static int64_t prime_factor_digit_sum(int64_t value)
{
    int64_t sum = 0;
    int64_t remainder = value;
    for (int64_t factor = 2; factor <= value / factor; ++factor) {
        while (remainder % factor == 0) {
            sum += digit_sum(factor);
            remainder /= factor;
        }
    }
    if (remainder > 1) sum += digit_sum(remainder);
    return sum;
}

int64_t smith_number(int64_t value)
{
    if (value < 1 || value > 2147483647) return -1;
    if (is_prime(value)) return 0;
    return digit_sum(value) == prime_factor_digit_sum(value);
}
