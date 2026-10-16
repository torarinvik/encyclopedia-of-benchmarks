#include <stddef.h>
#include <stdint.h>

#define MAX_DIMENSION 32
#define MAX_INPUT_LENGTH (4 + 2 * MAX_DIMENSION * MAX_DIMENSION + 1)

int64_t checkequal(const int64_t *values, size_t length) {
    if (values == NULL || length < 4 || length > MAX_INPUT_LENGTH) {
        return -1;
    }

    const int64_t rows_a = values[0];
    const int64_t columns_a = values[1];
    const int64_t rows_b = values[2];
    const int64_t columns_b = values[3];
    if (rows_a < 0 || rows_a > MAX_DIMENSION || columns_a < 0 || columns_a > MAX_DIMENSION
            || rows_b < 0 || rows_b > MAX_DIMENSION || columns_b < 0 || columns_b > MAX_DIMENSION) {
        return -1;
    }

    const size_t count_a = (size_t)rows_a * (size_t)columns_a;
    const size_t count_b = (size_t)rows_b * (size_t)columns_b;
    if (length != 4 + count_a + count_b) {
        return -1;
    }
    if (rows_a != rows_b || columns_a != columns_b) {
        return 0;
    }
    for (size_t index = 0; index < count_a; ++index) {
        if (values[4 + index] != values[4 + count_a + index]) {
            return 0;
        }
    }
    return 1;
}
