#include <stddef.h>
#include <stdint.h>

static int is_palindromic(uint32_t value)
{
    uint32_t reversed = 0, remaining = value;
    while (remaining > 0) {
        reversed = 10 * reversed + remaining % 10;
        remaining /= 10;
    }
    return reversed == value;
}

int64_t euler_problem_4(const int64_t *input, size_t length)
{
    if (input == NULL || length < 1 || length > 2 || input[0] < 1 || input[0] > 3 || length != 1) return -1;
    uint32_t lower = 1;
    for (int digit = 1; digit < (int)input[0]; ++digit) lower *= 10;
    uint32_t upper = lower * 10 - 1;
    uint32_t maximum = 0;
    for (uint32_t left = lower; left <= upper; ++left) {
        for (uint32_t right = lower; right <= upper; ++right) {
            uint32_t product = left * right;
            if (product > maximum && is_palindromic(product)) maximum = product;
        }
    }
    return (int64_t)maximum;
}
