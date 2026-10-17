#include <stddef.h>
#include <stdint.h>

#define MAX_DIMENSION 63
#define MAX_INPUT_VALUES (2 + MAX_DIMENSION * MAX_DIMENSION)
#define MAX_ABS_CELL INT64_C(1000000)
#define INVALID_RESULT (-1.0e300)

double sparsity(const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || length > MAX_INPUT_VALUES) return INVALID_RESULT;
    const int64_t rows_value = input[0];
    const int64_t columns_value = input[1];
    if (rows_value < 1 || rows_value > MAX_DIMENSION || columns_value < 1 || columns_value > MAX_DIMENSION)
        return INVALID_RESULT;
    const size_t rows = (size_t)rows_value;
    const size_t columns = (size_t)columns_value;
    const size_t total = rows * columns;
    if (length != 2 + total) return INVALID_RESULT;

    size_t zero_count = 0;
    for (size_t index = 0; index < total; ++index) {
        const int64_t value = input[2 + index];
        if (value < -MAX_ABS_CELL || value > MAX_ABS_CELL) return INVALID_RESULT;
        if (value == 0) ++zero_count;
    }
    return (double)zero_count / (double)total;
}
