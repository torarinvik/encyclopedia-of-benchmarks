/* Multiply bounded nonnegative operands with a three-product decimal split. */
#include <stddef.h>
#include <stdint.h>

#define MAX_OPERAND INT64_C(1000000)

static int64_t power_of_ten(unsigned digits) {
    int64_t result = 1;
    for (unsigned index = 0; index < digits; ++index) result *= 10;
    return result;
}

static int decimal_digits(int64_t value) {
    int digits = 1;
    while (value >= 10) { value /= 10; ++digits; }
    return digits;
}

static int64_t karatsuba_product(int64_t left, int64_t right) {
    if (left < 10 || right < 10) return left * right;
    int digits = decimal_digits(left > right ? left : right);
    int64_t split = power_of_ten((unsigned)(digits / 2));
    int64_t left_high = left / split, left_low = left % split;
    int64_t right_high = right / split, right_low = right % split;
    int64_t low_product = karatsuba_product(left_low, right_low);
    int64_t high_product = karatsuba_product(left_high, right_high);
    int64_t sum_product = karatsuba_product(left_high + left_low, right_high + right_low);
    return high_product * split * split + (sum_product - high_product - low_product) * split + low_product;
}

int64_t karatsuba(const int64_t *input, size_t length) {
    if (input == NULL || length != 2) return -1;
    if (input[0] < 0 || input[0] > MAX_OPERAND || input[1] < 0 || input[1] > MAX_OPERAND) return -1;
    return karatsuba_product(input[0], input[1]);
}
