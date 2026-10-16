#include <stddef.h>
#include <stdint.h>

#define MAX_RUNES 8
#define MAX_INPUT_LENGTH (MAX_RUNES + 2)
#define BYTES_PER_VALUE 4

static int is_unicode_scalar(int64_t value)
{
    return value >= 0 && value <= 0x10ffff && !(value >= 0xd800 && value <= 0xdfff);
}

static void store_u32_le(uint8_t *output, size_t position, uint32_t value)
{
    for (size_t byte = 0; byte < BYTES_PER_VALUE; ++byte)
        output[position + byte] = (uint8_t)(value >> (byte * 8));
}

static void emit_row(const int32_t *current, size_t length, uint8_t *output,
                     size_t *output_cursor, size_t *row_count)
{
    store_u32_le(output, *output_cursor, (uint32_t)length);
    *output_cursor += BYTES_PER_VALUE;
    for (size_t item = 0; item < length; ++item) {
        store_u32_le(output, *output_cursor, (uint32_t)current[item]);
        *output_cursor += BYTES_PER_VALUE;
    }
    ++*row_count;
}

static void generate(const int32_t *values, size_t n, size_t start,
                     int32_t *current, size_t current_length, uint8_t *output,
                     size_t *output_cursor, size_t *row_count)
{
    for (size_t index = start; index < n; ++index) {
        current[current_length] = values[index];
        emit_row(current, current_length + 1, output, output_cursor, row_count);
        generate(values, n, index + 1, current, current_length + 1,
                 output, output_cursor, row_count);
    }
}

int64_t non_empty_subsequences(const int64_t *input, size_t length,
                               uint8_t *output, size_t output_capacity)
{
    if (input == NULL || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t count_value = input[0];
    if (count_value < 1 || count_value > MAX_RUNES ||
        length != (size_t)count_value + 1) return -1;
    const size_t count = (size_t)count_value;
    int32_t values[MAX_RUNES];
    for (size_t index = 0; index < count; ++index) {
        const int64_t value = input[index + 1];
        if (!is_unicode_scalar(value)) return -1;
        values[index] = (int32_t)value;
    }

    const size_t row_count = ((size_t)1 << count) - 1;
    const size_t value_count = count * ((size_t)1 << (count - 1));
    const size_t required = (row_count + value_count) * BYTES_PER_VALUE;
    if (output_capacity < required || output == NULL) return -2;

    int32_t current[MAX_RUNES];
    size_t output_cursor = 0;
    size_t emitted = 0;
    generate(values, count, 0, current, 0, output, &output_cursor, &emitted);
    return (int64_t)emitted;
}
