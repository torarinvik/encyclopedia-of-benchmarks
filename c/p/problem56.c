/* Exact decimal-digit power search for Project Euler 56. */
#include <stdint.h>
static int multiply_digits(int digits[512], int length, int factor) {
    int carry = 0;
    for (int i = 0; i < length; ++i) { int value = digits[i] * factor + carry; digits[i] = value % 10; carry = value / 10; }
    while (carry > 0) { digits[length++] = carry % 10; carry /= 10; }
    return length;
}
int64_t problem56(int64_t a, int64_t b) {
    if (a < 1 || a > 200 || b < 1 || b > 200) return -1;
    int64_t best = 0;
    for (int64_t base = 0; base < a; ++base) {
        int digits[512] = {1}; int length = 1;
        for (int64_t power = 0; power < b; ++power) {
            int64_t sum = 0; for (int i = 0; i < length; ++i) sum += digits[i];
            if (sum > best) best = sum;
            if (power + 1 < b) length = multiply_digits(digits, length, (int)base);
        }
    }
    return best;
}
