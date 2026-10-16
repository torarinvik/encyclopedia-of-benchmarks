#include <stddef.h>
#include <stdint.h>

int64_t excess_3_code(int64_t value, uint8_t *output, size_t output_capacity) {
    uint8_t digits[19];
    size_t count = 0;
    uint64_t number = value < 0 ? 0 : (uint64_t)value;
    do {
        digits[count++] = (uint8_t)(number % 10);
        number /= 10;
    } while (number != 0);
    const size_t output_length = 2 + 4 * count;
    if (output == NULL || output_capacity < output_length) return -2;
    output[0] = '0';
    output[1] = 'b';
    size_t position = 2;
    while (count > 0) {
        const unsigned nibble = (unsigned)digits[--count] + 3U;
        for (unsigned bit = 8; bit != 0; bit >>= 1)
            output[position++] = (uint8_t)((nibble & bit) ? '1' : '0');
    }
    return (int64_t)output_length;
}
