#include <stddef.h>
#include <stdint.h>

int64_t format_phone_number(const int64_t *values, size_t length,
                            uint8_t *output, size_t output_capacity)
{
    if (values == NULL || length != 10) return -1;
    for (size_t i = 0; i < 10; ++i) {
        if (values[i] < '0' || values[i] > '9') return -1;
    }
    if (output == NULL || output_capacity < 14) return -2;

    output[0] = '(';
    output[1] = (uint8_t)values[0];
    output[2] = (uint8_t)values[1];
    output[3] = (uint8_t)values[2];
    output[4] = ')';
    output[5] = ' ';
    output[6] = (uint8_t)values[3];
    output[7] = (uint8_t)values[4];
    output[8] = (uint8_t)values[5];
    output[9] = '-';
    for (size_t i = 6; i < 10; ++i) output[10 + i - 6] = (uint8_t)values[i];
    return 14;
}
