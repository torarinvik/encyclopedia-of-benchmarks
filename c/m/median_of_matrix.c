#include <stddef.h>
#include <stdint.h>

#define MAX_ROWS 16
#define MAX_CELLS 128
#define MAX_INPUT_WORDS (1 + MAX_ROWS + MAX_CELLS)

static void put_i32_le(uint8_t *output, int32_t value) {
    const uint32_t bits = (uint32_t)value;
    for (size_t byte = 0; byte < 4; ++byte)
        output[byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t median_of_matrix(const int64_t *input, size_t length,
                         uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1 || length > MAX_INPUT_WORDS) return -1;
    if (input[0] < 0 || input[0] > MAX_ROWS) return -1;

    const size_t row_count = (size_t)input[0];
    size_t cursor = 1;
    size_t value_count = 0;
    int32_t values[MAX_CELLS];
    for (size_t row = 0; row < row_count; ++row) {
        if (cursor >= length) return -1;
        const int64_t row_length = input[cursor++];
        if (row_length == -1) continue;
        if (row_length < 0 || row_length > MAX_CELLS) return -1;
        const size_t cells = (size_t)row_length;
        if (cells > MAX_CELLS - value_count || cells > length - cursor) return -1;
        for (size_t column = 0; column < cells; ++column) {
            const int64_t value = input[cursor++];
            if (value < INT32_MIN || value > INT32_MAX) return -1;
            values[value_count++] = (int32_t)value;
        }
    }
    if (cursor != length || value_count == 0) return -1;

    for (size_t index = 1; index < value_count; ++index) {
        const int32_t value = values[index];
        size_t position = index;
        while (position > 0 && values[position - 1] > value) {
            values[position] = values[position - 1];
            --position;
        }
        values[position] = value;
    }

    if (output == NULL || capacity < 4) return -2;
    uint8_t buffer[4];
    put_i32_le(buffer, values[(value_count - 1) / 2]);
    for (size_t byte = 0; byte < sizeof buffer; ++byte) output[byte] = buffer[byte];
    return 4;
}
