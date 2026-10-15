/* Return the first source-ordered Goldbach pair as two little-endian i32 values. */
#include <stddef.h>
#include <stdint.h>

static int is_prime(int64_t value)
{
    if (value == 2) return 1;
    if (value < 2 || value % 2 == 0) return 0;
    for (int64_t divisor = 3; divisor <= value / divisor; divisor += 2)
        if (value % divisor == 0) return 0;
    return 1;
}

int64_t goldbach_conjecture(int64_t number, uint8_t *output, size_t output_capacity)
{
    if (number < 4 || number > 4096 || number % 2 != 0) return -1;
    if (output == NULL || output_capacity < 8) return -2;
    for (int64_t first = 0; first <= number / 2; ++first) {
        int64_t second = number - first;
        if (is_prime(first) && is_prime(second)) {
            uint32_t pair[2] = {(uint32_t)first, (uint32_t)second};
            for (size_t j = 0; j < 2; ++j)
                for (size_t b = 0; b < 4; ++b)
                    output[4 * j + b] = (uint8_t)(pair[j] >> (8 * b));
            return 8;
        }
    }
    return -1;
}
