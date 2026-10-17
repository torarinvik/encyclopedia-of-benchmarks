/* Decimal-string Fibonacci using the pinned manual-add recurrence. */
#include <stddef.h>
#include <stdint.h>

#define MAX_N 256
#define DECIMAL_CAPACITY 80

static size_t add_decimal(const char *left, size_t left_length,
                          const char *right, size_t right_length,
                          char *result)
{
    char reversed[DECIMAL_CAPACITY];
    size_t length = 0;
    int carry = 0;
    while (left_length > 0 || right_length > 0 || carry != 0) {
        int left_digit = left_length > 0 ? left[--left_length] - '0' : 0;
        int right_digit = right_length > 0 ? right[--right_length] - '0' : 0;
        int sum = left_digit + right_digit + carry;
        reversed[length++] = (char)('0' + (sum % 10));
        carry = sum / 10;
    }
    for (size_t i = 0; i < length; ++i) result[i] = reversed[length - 1 - i];
    result[length] = '\0';
    return length;
}

int64_t string_fibonacci(const int64_t *input, size_t length,
                         uint8_t *output, size_t capacity)
{
    if (input == NULL || length != 1) return -1;
    if (input[0] < 0 || input[0] > MAX_N) return -1;

    char fib_minus_one[DECIMAL_CAPACITY] = "1";
    char fib_minus_two[DECIMAL_CAPACITY] = "0";
    size_t minus_one_length = 1;
    size_t minus_two_length = 1;
    for (size_t i = 0; i < (size_t)input[0]; ++i) {
        char sum[DECIMAL_CAPACITY];
        size_t sum_length = add_decimal(fib_minus_one, minus_one_length,
                                        fib_minus_two, minus_two_length, sum);
        for (size_t j = 0; j < minus_one_length; ++j) fib_minus_two[j] = fib_minus_one[j];
        minus_two_length = minus_one_length;
        for (size_t j = 0; j < sum_length; ++j) fib_minus_one[j] = sum[j];
        fib_minus_one[sum_length] = '\0';
        minus_one_length = sum_length;
    }

    if (output == NULL || capacity < minus_two_length) return -2;
    for (size_t i = 0; i < minus_two_length; ++i) output[i] = (uint8_t)fib_minus_two[i];
    return (int64_t)minus_two_length;
}
