#include <stddef.h>
#include <stdint.h>

#define MAX_DIMENSION INT64_C(63)
#define MAX_INPUT_VALUES (3 + 63 * 63)
#define MAX_ABS_CELL INT64_C(1000000000000)
#define CELL_SCALE 1.0e12
#define TOLERANCE 1.0e-9

int64_t stochastic_matrix(const int64_t *input, size_t length) {
    if (input == NULL || length < 3 || length > MAX_INPUT_VALUES) return -1;

    const int64_t mode = input[0];
    const int64_t rows_value = input[1];
    const int64_t columns_value = input[2];
    if ((mode != 0 && mode != 1) || rows_value < 1 || rows_value > MAX_DIMENSION ||
        columns_value < 1 || columns_value > MAX_DIMENSION) return -1;

    const size_t rows = (size_t)rows_value;
    const size_t columns = (size_t)columns_value;
    const size_t total = rows * columns;
    if (length != 3 + total) return -1;

    for (size_t index = 0; index < total; ++index) {
        const int64_t units = input[3 + index];
        if (units < -MAX_ABS_CELL || units > MAX_ABS_CELL) return -1;
    }

    if (mode == 0) {
        for (size_t row = 0; row < rows; ++row) {
            double sum = 0.0;
            for (size_t column = 0; column < columns; ++column) {
                const double value = (double)input[3 + row * columns + column] / CELL_SCALE;
                if (value < 0.0) return 0;
                sum += value;
            }
            const double difference = sum - 1.0;
            if (difference > TOLERANCE || difference < -TOLERANCE) return 0;
        }
    } else {
        for (size_t column = 0; column < columns; ++column) {
            double sum = 0.0;
            for (size_t row = 0; row < rows; ++row) {
                const double value = (double)input[3 + row * columns + column] / CELL_SCALE;
                if (value < 0.0) return 0;
                sum += value;
            }
            const double difference = sum - 1.0;
            if (difference > TOLERANCE || difference < -TOLERANCE) return 0;
        }
    }
    return 1;
}
