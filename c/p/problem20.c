#include <stdint.h>

int64_t problem20(int64_t n)
{
    if (n < 0 || n > 100) return -1;
    int digits[200] = {1};
    int length = 1;
    for (int64_t factor = 2; factor <= n; ++factor) {
        int64_t carry = 0;
        for (int index = 0; index < length; ++index) {
            const int64_t value = (int64_t)digits[index] * factor + carry;
            digits[index] = (int)(value % 10);
            carry = value / 10;
        }
        while (carry > 0) {
            digits[length++] = (int)(carry % 10);
            carry /= 10;
        }
    }
    int64_t sum = 0;
    for (int index = 0; index < length; ++index) sum += digits[index];
    return sum;
}
