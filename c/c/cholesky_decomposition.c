#include <math.h>
#include <stddef.h>
#include <stdint.h>
#include <string.h>

#define MAX_DIMENSION 6
#define MAX_ENTRY_MICRO 1000000000LL

static void write_f64_le(uint8_t *output, size_t offset, double value) {
    uint64_t bits;
    memcpy(&bits, &value, sizeof(bits));
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t cholesky_decomposition(const int64_t *values, size_t length,
                               uint8_t *output, size_t output_capacity) {
    if (values == NULL || length < 1 || values[0] < 1 || values[0] > MAX_DIMENSION) return -1;
    const size_t n = (size_t)values[0];
    if (length != 1 + n * n) return -1;

    double matrix[MAX_DIMENSION * MAX_DIMENSION] = {0};
    double lower[MAX_DIMENSION * MAX_DIMENSION] = {0};
    for (size_t index = 0; index < n * n; ++index) {
        const int64_t scaled = values[index + 1];
        if (scaled < -MAX_ENTRY_MICRO || scaled > MAX_ENTRY_MICRO) return -1;
        matrix[index] = (double)scaled / 1000000.0;
    }
    for (size_t row = 0; row < n; ++row) {
        for (size_t column = 0; column < n; ++column) {
            const double left = matrix[row * n + column];
            const double right = matrix[column * n + row];
            if (fabs(left - right) > 1.0e-8 + 1.0e-5 * fabs(right)) return -1;
        }
    }

    for (size_t row = 0; row < n; ++row) {
        for (size_t column = 0; column <= row; ++column) {
            double sum = 0.0;
            for (size_t index = 0; index < column; ++index)
                sum += lower[row * n + index] * lower[column * n + index];
            const double residual = matrix[row * n + column] - sum;
            if (row == column) {
                if (residual <= 0.0) return -1;
                lower[row * n + column] = sqrt(residual);
            } else {
                lower[row * n + column] = residual / lower[column * n + column];
            }
        }
    }

    const size_t output_bytes = n * n * 8;
    if (output_bytes > output_capacity || output == NULL) return -2;
    for (size_t index = 0; index < n * n; ++index)
        write_f64_le(output, index * 8, lower[index]);
    return (int64_t)output_bytes;
}
