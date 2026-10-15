/* Return whether a positive integer's decimal digit sum equals its product. */
#include <stdint.h>

int64_t spy_number(int64_t input)
{
    if (input <= 0) return 0;
    int64_t digit_sum = 0;
    int64_t digit_product = 1;
    while (input > 0) {
        const int64_t digit = input % 10;
        digit_sum += digit;
        digit_product *= digit;
        input /= 10;
    }
    return digit_sum == digit_product;
}
