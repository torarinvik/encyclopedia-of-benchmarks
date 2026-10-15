/* Smallest base in which a nonnegative integer is palindromic. */
#include <stddef.h>
#include <stdint.h>

static int is_palindromic_in_base(int64_t number, int64_t base)
{
    if (number <= 1) return 1;
    if (number % base == 0) return 0;
    int64_t remaining = number;
    int64_t reversed = 0;
    while (remaining > 0) {
        reversed = reversed * base + remaining % base;
        remaining /= base;
    }
    return reversed == number;
}

int64_t lowest_base_palindrome(int64_t number)
{
    if (number < 0 || number > 64) return -1;
    int64_t base = 2;
    while (!is_palindromic_in_base(number, base)) ++base;
    return base;
}
