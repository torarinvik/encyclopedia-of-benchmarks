/* Decimal digit sum of a bounded single-digit base power. */
#include <stddef.h>
#include <stdint.h>

#define MAX_DIGITS 1001

int64_t problem016_power_digit_sum(const int64_t *values, size_t length)
{
    if (values == NULL || length != 2) return -1;
    const int64_t base = values[0];
    const int64_t exponent = values[1];
    if (base < 0 || base > 9 || exponent < 0 || exponent > 1000) return -1;

    int64_t digits[MAX_DIGITS] = {0};
    size_t digit_count = 1;
    digits[0] = base;

    for (int64_t power = 1; power < exponent; ++power) {
        int64_t carry = 0;
        for (size_t index = 0; index < digit_count; ++index) {
            const int64_t product = digits[index] * base + carry;
            digits[index] = product % 10;
            carry = product / 10;
        }
        while (carry > 0) {
            if (digit_count >= MAX_DIGITS) return -1;
            digits[digit_count++] = carry % 10;
            carry /= 10;
        }
    }

    int64_t sum = 0;
    for (size_t index = 0; index < digit_count; ++index) sum += digits[index];
    return sum;
}
