#include <stdint.h>

int64_t problem63(int64_t max_base, int64_t max_power)
{
    if (max_base > 10) max_base = 10;
    if (max_power > 22) max_power = 22;
    int64_t count = 0;
    for (int64_t base = 1; base < max_base; ++base) {
        for (int64_t power = 1; power < max_power; ++power) {
            int digits[32] = {1};
            int length = 1;
            for (int64_t exponent = 0; exponent < power; ++exponent) {
                int carry = 0;
                for (int index = 0; index < length; ++index) {
                    int value = digits[index] * (int)base + carry;
                    digits[index] = value % 10;
                    carry = value / 10;
                }
                while (carry > 0) {
                    digits[length++] = carry % 10;
                    carry /= 10;
                }
            }
            if (length == power) ++count;
        }
    }
    return count;
}
