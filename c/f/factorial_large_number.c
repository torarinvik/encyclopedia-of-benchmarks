/* Multiply a base-10 digit array by each factor through n. */
#include <stddef.h>
#include <stdint.h>

#define MAX_N 100
#define MAX_DIGITS 160

int64_t factorial_large_number(int64_t n, uint8_t *output, size_t output_capacity)
{
    if (n < 0 || n > MAX_N) return -1;
    int64_t digits[MAX_DIGITS] = {1};
    size_t digit_count = 1;
    for (int64_t factor = 2; factor <= n; ++factor) {
        int64_t carry = 0;
        for (size_t i = 0; i < digit_count; ++i) {
            const int64_t product = digits[i] * factor + carry;
            digits[i] = product % 10;
            carry = product / 10;
        }
        while (carry != 0) {
            digits[digit_count++] = carry % 10;
            carry /= 10;
        }
    }
    if (output == NULL || output_capacity < digit_count) return -2;
    for (size_t i = 0; i < digit_count; ++i)
        output[i] = (uint8_t)('0' + digits[digit_count - i - 1]);
    return (int64_t)digit_count;
}
