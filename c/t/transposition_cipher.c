#include <stddef.h>
#include <stdint.h>
#include <string.h>

#define MAX_TEXT 256
#define MAX_INPUT 259

int64_t transposition_cipher(const int64_t *input, size_t length,
                             uint8_t *output, size_t output_capacity) {
    if (input == NULL || length < 6 || length > MAX_INPUT) return -1;
    const int64_t mode = input[0], key64 = input[1], n64 = input[2];
    if ((mode != 0 && mode != 1) || n64 < 3 || n64 > MAX_TEXT ||
        key64 < 2 || key64 >= n64 || length != 3 + (size_t)n64) return -1;
    const size_t key = (size_t)key64, n = (size_t)n64;
    for (size_t i = 0; i < n; ++i) if (input[3 + i] < 0 || input[3 + i] > 127) return -1;
    if (output == NULL || output_capacity < n) return -2;

    uint8_t transformed[MAX_TEXT];
    if (mode == 0) {
        size_t written = 0;
        for (size_t column = 0; column < key; ++column)
            for (size_t index = column; index < n; index += key)
                transformed[written++] = (uint8_t)input[3 + index];
    } else {
        const size_t columns = (n + key - 1) / key;
        const size_t shaded = columns * key - n;
        const size_t final_column_rows = key - shaded;
        size_t offsets[MAX_TEXT], seen[MAX_TEXT] = {0}, total = 0;
        for (size_t column = 0; column < columns; ++column) {
            offsets[column] = total;
            total += column + 1 == columns ? final_column_rows : key;
        }
        size_t row = 0, column = 0;
        for (size_t i = 0; i < n; ++i) {
            transformed[offsets[column] + seen[column]++] = (uint8_t)input[3 + i];
            ++column;
            if (column == columns || (column == columns - 1 && row >= final_column_rows)) {
                column = 0;
                ++row;
            }
        }
    }
    memcpy(output, transformed, n);
    return (int64_t)n;
}
