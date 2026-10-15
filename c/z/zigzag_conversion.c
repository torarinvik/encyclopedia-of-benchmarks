/* Arrange ASCII letters in zigzag rows and read them row by row. */
#include <stddef.h>
#include <stdint.h>

#define MAX_INPUT_LENGTH 1025
#define MAX_ROWS 1024

static int is_ascii_letter(int64_t value)
{
    return (value >= 'A' && value <= 'Z') || (value >= 'a' && value <= 'z');
}

int64_t zigzag_conversion(const int64_t *values, size_t length,
                          uint8_t *output, size_t output_capacity)
{
    if (length == 0 || length > MAX_INPUT_LENGTH || values == NULL) return -1;
    const int64_t requested_rows = values[0];
    if (requested_rows < 1 || requested_rows > MAX_ROWS) return -1;
    const size_t text_length = length - 1;
    for (size_t index = 0; index < text_length; ++index)
        if (!is_ascii_letter(values[index + 1])) return -1;
    if (output_capacity < text_length || (text_length != 0 && output == NULL)) return -2;
    if (text_length == 0) return 0;
    const size_t rows = (size_t)requested_rows;
    if (rows == 1 || rows >= text_length) {
        for (size_t index = 0; index < text_length; ++index)
            output[index] = (uint8_t)values[index + 1];
        return (int64_t)text_length;
    }
    const size_t cycle = 2 * (rows - 1);
    size_t written = 0;
    for (size_t row = 0; row < rows; ++row) {
        size_t index = row;
        size_t step = row == 0 || row + 1 == rows ? cycle : cycle - 2 * row;
        while (index < text_length) {
            output[written++] = (uint8_t)values[index + 1];
            index += step;
            if (row > 0 && row + 1 < rows) step = cycle - step;
        }
    }
    return (int64_t)written;
}
