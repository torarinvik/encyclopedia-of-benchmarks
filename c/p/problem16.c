#include <stdint.h>

int64_t problem16(int64_t exponent)
{
    if (exponent < 0 || exponent > 1000) return -1;
    int digits[400] = {1};
    int length = 1;
    for (int64_t power = 0; power < exponent; ++power) {
        int carry = 0;
        for (int index = 0; index < length; ++index) {
            int value = digits[index] * 2 + carry;
            digits[index] = value % 10;
            carry = value / 10;
        }
        while (carry > 0) {
            digits[length++] = carry % 10;
            carry /= 10;
        }
    }
    int64_t sum = 0;
    for (int index = 0; index < length; ++index) sum += digits[index];
    return sum;
}
