#include <stdint.h>

#define MAX_DIGITS 9

static int problem41_is_prime(int64_t number)
{
    if (number < 2) return 0;
    if (number < 4) return 1;
    if (number % 2 == 0 || number % 3 == 0) return 0;
    for (int64_t divisor = 5; divisor <= number / divisor; divisor += 6) {
        if (number % divisor == 0 || number % (divisor + 2) == 0) return 0;
    }
    return 1;
}

static int64_t problem41_search(int digits, int depth, uint16_t used, int64_t value)
{
    if (depth == digits) return problem41_is_prime(value) ? value : 0;
    int64_t best = 0;
    for (int digit = 1; digit <= digits; ++digit) {
        const uint16_t bit = (uint16_t)(1u << digit);
        if ((used & bit) != 0) continue;
        const int64_t candidate = problem41_search(digits, depth + 1,
                                                   (uint16_t)(used | bit),
                                                   value * 10 + digit);
        if (candidate > best) best = candidate;
    }
    return best;
}

int64_t problem41(int64_t digits)
{
    if (digits < 1 || digits > MAX_DIGITS) return -1;
    return problem41_search((int)digits, 0, 0, 0);
}
