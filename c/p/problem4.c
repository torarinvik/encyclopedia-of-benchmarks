#include <stdint.h>

static int is_palindrome(int64_t value)
{
    int64_t original = value;
    int64_t reversed = 0;
    while (value > 0) {
        reversed = reversed * 10 + value % 10;
        value /= 10;
    }
    return reversed == original;
}

int64_t problem4(int64_t digits)
{
    if (digits < 1 || digits > 3) return -1;
    int64_t minimum = digits == 1 ? 1 : (digits == 2 ? 10 : 100);
    int64_t maximum = digits == 1 ? 9 : (digits == 2 ? 99 : 999);
    int64_t largest = 0;
    for (int64_t first = maximum; first >= minimum && first * maximum > largest; --first) {
        for (int64_t second = maximum; second >= first && first * second > largest; --second) {
            int64_t product = first * second;
            if (is_palindrome(product)) largest = product;
        }
    }
    return largest;
}
