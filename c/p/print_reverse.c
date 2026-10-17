#include <stddef.h>
#include <stdint.h>

#define MAX_VALUES 256
#define MAX_PARSEABLE_INPUT_LENGTH (MAX_VALUES + 2)
#define MAX_OUTPUT_BYTES 3836
#define I32_MIN_VALUE (-INT64_C(2147483647) - 1)
#define I32_MAX_VALUE INT64_C(2147483647)

static void append_decimal(uint8_t *buffer, size_t *position, int64_t value)
{
    uint8_t digits[10];
    size_t count = 0;
    uint64_t magnitude;
    if (value < 0) {
        buffer[(*position)++] = (uint8_t)'-';
        magnitude = (uint64_t)(-value);
    } else {
        magnitude = (uint64_t)value;
    }
    do {
        digits[count++] = (uint8_t)('0' + magnitude % 10);
        magnitude /= 10;
    } while (magnitude != 0);
    while (count > 0) buffer[(*position)++] = digits[--count];
}

int64_t print_reverse(const int64_t *values, size_t length,
                      uint8_t *output, size_t output_capacity)
{
    if (length > MAX_PARSEABLE_INPUT_LENGTH || length > MAX_VALUES) return -1;
    if (length > 0 && values == NULL) return -1;
    for (size_t index = 0; index < length; ++index)
        if (values[index] < I32_MIN_VALUE || values[index] > I32_MAX_VALUE) return -1;

    uint8_t encoded[MAX_OUTPUT_BYTES];
    size_t written = 0;
    for (size_t remaining = length; remaining > 0; --remaining) {
        if (written != 0) {
            encoded[written++] = (uint8_t)' ';
            encoded[written++] = (uint8_t)'<';
            encoded[written++] = (uint8_t)'-';
            encoded[written++] = (uint8_t)' ';
        }
        append_decimal(encoded, &written, values[remaining - 1]);
    }

    if (output == NULL || output_capacity < written) return -2;
    for (size_t index = 0; index < written; ++index) output[index] = encoded[index];
    return (int64_t)written;
}
