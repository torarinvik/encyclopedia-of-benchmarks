#include <stddef.h>
#include <stdint.h>

#define SIEVE_LIMIT INT64_C(8192)
#define MAX_ITERATIONS INT64_C(64)

int64_t sieve(int64_t iterations, uint8_t *output, size_t output_capacity)
{
    if (iterations < 0 || iterations > MAX_ITERATIONS) return -1;

    uint8_t flags[SIEVE_LIMIT + 1];
    int64_t count = 0;
    for (int64_t pass = 0; pass < iterations; ++pass) {
        count = 0;
        for (int64_t value = 2; value <= SIEVE_LIMIT; ++value) flags[value] = 1;
        for (int64_t value = 2; value <= SIEVE_LIMIT; ++value) {
            if (flags[value]) {
                ++count;
                for (int64_t multiple = value + value; multiple <= SIEVE_LIMIT; multiple += value)
                    flags[multiple] = 0;
            }
        }
    }

    const char prefix[] = "Count: ";
    uint8_t reversed_digits[10];
    size_t digit_count = 0;
    int64_t remaining = count;
    do {
        reversed_digits[digit_count++] = (uint8_t)('0' + remaining % 10);
        remaining /= 10;
    } while (remaining != 0);
    const size_t required = sizeof(prefix) - 1 + digit_count + 1;
    if (output == NULL || output_capacity < required) return -2;
    for (size_t index = 0; index < sizeof(prefix) - 1; ++index)
        output[index] = (uint8_t)prefix[index];
    for (size_t index = 0; index < digit_count; ++index)
        output[sizeof(prefix) - 1 + index] = reversed_digits[digit_count - index - 1];
    output[required - 1] = (uint8_t)'\n';
    return (int64_t)required;
}
