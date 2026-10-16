/* Count non-bouncy positive integers with at most the requested digits. */
#include <stdint.h>

#define MAX_DIGITS INT64_C(100)

static int64_t choose_integer(int64_t n, int64_t r)
{
    int64_t result = 1;
    for (int64_t i = 1; i <= r; ++i) result = result * (n + 1 - i) / i;
    return result;
}

static int64_t non_bouncy_exact(int64_t digits)
{
    return choose_integer(8 + digits, digits) + choose_integer(9 + digits, digits) - 10;
}

int64_t problem113(int64_t num_digits)
{
    if (num_digits > MAX_DIGITS) return -1;
    int64_t total = 0;
    for (int64_t digits = 1; digits <= num_digits; ++digits)
        total += non_bouncy_exact(digits);
    return total;
}
