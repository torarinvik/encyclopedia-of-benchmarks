/* Separate signed decimal digits; direction 0 is reverse and 1 is forward. */
#include <stddef.h>
#include <stdint.h>

int64_t digit_separation(const int64_t *input, size_t input_length,
                         uint8_t *output, size_t output_capacity)
{
    if (input == NULL || input_length != 2 || (input[1] != 0 && input[1] != 1)) return -1;
    int64_t remaining = input[0];
    uint8_t digits[20];
    size_t count = 0;
    if (remaining == 0) digits[count++] = 0;
    while (remaining != 0) {
        const int64_t remainder = remaining % 10;
        digits[count++] = (uint8_t)(remainder < 0 ? -remainder : remainder);
        remaining /= 10;
    }
    if (output == NULL || output_capacity < count) return -2;
    for (size_t index = 0; index < count; ++index) {
        const size_t source = input[1] == 0 ? index : count - index - 1;
        output[index] = digits[source];
    }
    return (int64_t)count;
}
