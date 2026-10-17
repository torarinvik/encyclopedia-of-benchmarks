#include <math.h>
#include <stddef.h>
#include <stdint.h>
#include <string.h>

enum { MAX_ROWS = 64, MAX_COLUMNS = 8 };

static void write_f64_le(uint8_t *output, size_t offset, double value)
{
    uint64_t bits;
    memcpy(&bits, &value, sizeof(bits));
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8U * (unsigned)byte));
}

int64_t procentual_proximity(const int64_t *input, size_t length,
                             uint8_t *output, size_t output_capacity)
{
    if (input == NULL || length < 3 || length > 2 + MAX_COLUMNS + MAX_ROWS * MAX_COLUMNS) return -1;
    int64_t row_value = input[0], column_value = input[1];
    if (row_value < 1 || row_value > MAX_ROWS || column_value < 1 || column_value > MAX_COLUMNS) return -1;
    size_t rows = (size_t)row_value, columns = (size_t)column_value;
    if (length != 2 + columns + rows * columns) return -1;
    for (size_t column = 0; column < columns; ++column)
        if (input[2 + column] != 0 && input[2 + column] != 1) return -1;
    double data[MAX_ROWS][MAX_COLUMNS];
    for (size_t row = 0; row < rows; ++row) {
        for (size_t column = 0; column < columns; ++column) {
            int64_t value = input[2 + columns + row * columns + column];
            if (value < -10000 || value > 10000) return -1;
            data[row][column] = (double)value;
        }
    }
    size_t output_length = rows * (columns + 1) * 8;
    if (output == NULL || output_capacity < output_length) return -2;

    double scores[MAX_ROWS] = {0.0};
    for (size_t column = 0; column < columns; ++column) {
        double minimum = data[0][column], maximum = data[0][column];
        for (size_t row = 1; row < rows; ++row) {
            if (data[row][column] < minimum) minimum = data[row][column];
            if (data[row][column] > maximum) maximum = data[row][column];
        }
        int64_t weight = input[2 + column];
        if (minimum == maximum) {
            if (weight == 0) for (size_t row = 0; row < rows; ++row) scores[row] += 1.0;
        } else {
            double range = maximum - minimum;
            for (size_t row = 0; row < rows; ++row) {
                double item_score = (data[row][column] - minimum) / range;
                if (weight == 0) item_score = 1.0 - item_score;
                scores[row] += item_score;
            }
        }
    }
    size_t offset = 0;
    for (size_t row = 0; row < rows; ++row) {
        for (size_t column = 0; column < columns; ++column) {
            write_f64_le(output, offset, data[row][column]);
            offset += 8;
        }
        write_f64_le(output, offset, scores[row]);
        offset += 8;
    }
    return (int64_t)output_length;
}
