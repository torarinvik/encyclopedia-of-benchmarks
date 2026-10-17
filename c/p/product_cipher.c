#include <stddef.h>
#include <stdint.h>

#define MAX_INPUT_VALUES 259
#define MAX_TEXT_LENGTH 256
#define MAX_COLUMNS 64
#define MAX_OUTPUT_BYTES 315

int64_t product_cipher(const int64_t *input, size_t length,
                       uint8_t *output, size_t output_capacity)
{
    if (input == NULL || length < 2 || length > MAX_INPUT_VALUES) return -1;
    if (input[0] < 1 || input[0] > MAX_COLUMNS ||
        input[1] < 0 || input[1] > MAX_TEXT_LENGTH) return -1;

    const size_t columns = (size_t)input[0];
    const size_t text_length = (size_t)input[1];
    if (length != 2 + text_length) return -1;
    for (size_t index = 0; index < text_length; ++index) {
        const int64_t byte = input[2 + index];
        if (byte < 0 || byte > 127 || byte == 10 || byte == 13) return -1;
    }

    const size_t padded_length = text_length == 0
        ? 0
        : ((text_length + columns - 1) / columns) * columns;
    if (padded_length > MAX_OUTPUT_BYTES) return -1;
    if (padded_length == 0) return 0;
    if (output == NULL || output_capacity < padded_length) return -2;

    uint8_t padded[MAX_OUTPUT_BYTES] = {0};
    for (size_t index = 0; index < text_length; ++index)
        padded[index] = (uint8_t)(input[2 + index] + 5);
    for (size_t index = text_length; index < padded_length; ++index)
        padded[index] = (uint8_t)'/';

    size_t written = 0;
    const size_t rows = padded_length / columns;
    for (size_t column = 0; column < columns; ++column) {
        for (size_t row = 0; row < rows; ++row)
            output[written++] = padded[column + row * columns];
    }
    return (int64_t)written;
}
