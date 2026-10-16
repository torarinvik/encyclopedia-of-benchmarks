#include <stddef.h>
#include <stdint.h>

#define MAX_INPUT_LENGTH 10
#define PACKED_INPUT_LENGTH (MAX_INPUT_LENGTH + 1)
#define OUTPUT_LENGTH 8

static int is_digit(int64_t value) {
    return value >= 48 && value <= 57;
}

int64_t railway_time_conversion(const int64_t *values, size_t length,
                                uint8_t *output, size_t output_capacity) {
    if (values == NULL || length != PACKED_INPUT_LENGTH ||
        values[0] != MAX_INPUT_LENGTH) return -1;

    if (values[3] != 58 || values[6] != 58 ||
        !((values[9] == 65 && values[10] == 77) ||
          (values[9] == 80 && values[10] == 77)) ||
        !is_digit(values[1]) || !is_digit(values[2]) ||
        !is_digit(values[4]) || !is_digit(values[5]) ||
        !is_digit(values[7]) || !is_digit(values[8])) return -1;

    const int64_t hour = (values[1] - 48) * 10 + values[2] - 48;
    const int64_t minute = (values[4] - 48) * 10 + values[5] - 48;
    const int64_t second = (values[7] - 48) * 10 + values[8] - 48;
    if (hour < 1 || hour > 12 || minute > 59 || second > 59) return -1;

    if (output == NULL || output_capacity < OUTPUT_LENGTH) return -2;

    const int64_t hour24 = hour % 12 + (values[9] == 80 ? 12 : 0);
    output[0] = (uint8_t)(48 + hour24 / 10);
    output[1] = (uint8_t)(48 + hour24 % 10);
    output[2] = 58;
    output[3] = (uint8_t)values[4];
    output[4] = (uint8_t)values[5];
    output[5] = 58;
    output[6] = (uint8_t)values[7];
    output[7] = (uint8_t)values[8];
    return OUTPUT_LENGTH;
}
