#include <stddef.h>
#include <stdint.h>

#define MAX_INPUT_BYTES 4096
#define MAX_OUTPUT_BYTES 5675

static const uint8_t HEADER[] = "begin 640 uuencode.c \n";
static const uint8_t TRAILER[] = " \nend";

static uint8_t six_bit_symbol(unsigned value)
{
    return (uint8_t)(32u + (value & 63u));
}

int64_t uuencode(const int64_t *input, size_t length, uint8_t *output, size_t capacity)
{
    if (input == NULL || length > MAX_INPUT_BYTES) return -1;
    for (size_t i = 0; i < length; ++i)
        if (input[i] < 0 || input[i] > 255) return -1;

    const size_t line_count = (length + 44) / 45;
    const size_t required = (sizeof(HEADER) - 1) + 4 * ((length + 2) / 3) +
                            2 * line_count + (sizeof(TRAILER) - 1);
    if (output == NULL || capacity < required) return -2;

    size_t written = 0;
    for (size_t i = 0; i < sizeof(HEADER) - 1; ++i) output[written++] = HEADER[i];
    size_t offset = 0;
    while (offset < length) {
        const size_t line_length = length - offset < 45 ? length - offset : 45;
        const size_t line_end = offset + line_length;
        output[written++] = six_bit_symbol((unsigned)line_length);
        while (offset < line_end) {
            const unsigned first = (unsigned)input[offset];
            const unsigned has_second = offset + 1 < line_end;
            const unsigned has_third = offset + 2 < line_end;
            const unsigned second = has_second ? (unsigned)input[offset + 1] : 0;
            const unsigned third = has_third ? (unsigned)input[offset + 2] : 0;
            output[written++] = six_bit_symbol(first >> 2);
            output[written++] = six_bit_symbol((first << 4) | (second >> 4));
            output[written++] = has_second ? six_bit_symbol((second << 2) | (third >> 6)) : (uint8_t)'=';
            output[written++] = has_third ? six_bit_symbol(third) : (uint8_t)'=';
            offset += 3;
        }
        output[written++] = (uint8_t)'\n';
    }
    for (size_t i = 0; i < sizeof(TRAILER) - 1; ++i) output[written++] = TRAILER[i];
    return (int64_t)written;
}
