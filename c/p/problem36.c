#include <stdint.h>

#define MAX_LIMIT INT64_C(1000000)

static int problem36_is_decimal_palindrome(int64_t value)
{
    int64_t remaining = value;
    int64_t reversed = 0;
    while (remaining > 0) {
        reversed = reversed * 10 + remaining % 10;
        remaining /= 10;
    }
    return reversed == value;
}

static int problem36_is_binary_palindrome(int64_t value)
{
    int64_t remaining = value;
    int64_t reversed = 0;
    while (remaining > 0) {
        reversed = reversed * 2 + remaining % 2;
        remaining /= 2;
    }
    return reversed == value;
}

int64_t problem36(int64_t limit)
{
    if (limit < 0 || limit > MAX_LIMIT) return -1;
    int64_t total = 0;
    for (int64_t value = 1; value < limit; ++value) {
        if (problem36_is_decimal_palindrome(value) && problem36_is_binary_palindrome(value)) {
            total += value;
        }
    }
    return total;
}
