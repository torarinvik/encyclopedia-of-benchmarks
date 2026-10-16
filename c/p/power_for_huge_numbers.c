#include <stddef.h>
#include <stdint.h>

#define MAX_OUTPUT_BYTES 513

int64_t power_for_huge_numbers(const int64_t *input, size_t length,
                               uint8_t *output, size_t capacity) {
    if (input == NULL || length != 2) return -1;
    const int64_t base = input[0];
    const int64_t exponent = input[1];
    if (base < 1 || base > 10000 || exponent < 0 || exponent > 128) return -1;

    uint8_t digits[MAX_OUTPUT_BYTES] = {1};
    size_t digit_count = 1;
    for (int64_t power = 0; power < exponent; ++power) {
        uint32_t carry = 0;
        for (size_t i = 0; i < digit_count; ++i) {
            const uint32_t product = (uint32_t)digits[i] * (uint32_t)base + carry;
            digits[i] = (uint8_t)(product % 10);
            carry = product / 10;
        }
        while (carry != 0) {
            if (digit_count == MAX_OUTPUT_BYTES) return -1;
            digits[digit_count++] = (uint8_t)(carry % 10);
            carry /= 10;
        }
    }
    if (output == NULL || capacity < digit_count) return -2;
    for (size_t i = 0; i < digit_count; ++i)
        output[i] = (uint8_t)('0' + digits[digit_count - 1 - i]);
    return (int64_t)digit_count;
}
