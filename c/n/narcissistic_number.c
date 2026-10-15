/* Enumerate narcissistic numbers below limit, memoizing digit powers. */
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

int64_t narcissistic_number(int64_t limit, uint8_t *output, size_t output_capacity)
{
    if (limit > 100000) return -1;
    if (limit <= 0) return 0;
    int64_t numbers[32];
    int64_t powers[60] = {0};
    bool cached[60] = {false};
    size_t count = 0;
    for (int64_t number = 0; number < limit; ++number) {
        size_t digits = 1;
        for (int64_t remaining = number; remaining >= 10; remaining /= 10) ++digits;
        int64_t sum = 0;
        for (int64_t remaining = number; remaining > 0; remaining /= 10) {
            const size_t digit = (size_t)(remaining % 10);
            const size_t key = digits * 10 + digit;
            if (!cached[key]) {
                int64_t power = 1;
                for (size_t exponent = 0; exponent < digits; ++exponent) power *= (int64_t)digit;
                powers[key] = power;
                cached[key] = true;
            }
            sum += powers[key];
        }
        if (sum == number) {
            if (count == 32) return -1;
            numbers[count++] = number;
        }
    }
    const size_t required = count * 8;
    if (required == 0) return 0;
    if (output == NULL || output_capacity < required) return -2;
    for (size_t item = 0; item < count; ++item) {
        const uint64_t value = (uint64_t)numbers[item];
        for (size_t byte = 0; byte < 8; ++byte) {
            const unsigned shift = (unsigned)((7 - byte) * 8);
            output[item * 8 + byte] = (uint8_t)(value >> shift);
        }
    }
    return (int64_t)required;
}
