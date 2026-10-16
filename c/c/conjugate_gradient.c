#include <math.h>
#include <stddef.h>
#include <stdint.h>
#include <string.h>

#define MAX_DIMENSION 8
#define MAX_ENTRY_MICRO 1000000000LL
#define SCALE 1000000.0
#define TOLERANCE 1.0e-10
#define MAX_ITERATIONS 1000

static void write_f64_le(uint8_t *output, size_t offset, double value) {
    uint64_t bits;
    memcpy(&bits, &value, sizeof(bits));
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t conjugate_gradient(const int64_t *values, size_t length,
                           uint8_t *output, size_t output_capacity) {
    if (values == NULL || length < 1 || values[0] < 1 || values[0] > MAX_DIMENSION) return -1;
    const size_t n = (size_t)values[0];
    if (length != 1 + n * n + n) return -1;

    const size_t vector_offset = 1 + n * n;
    double matrix[MAX_DIMENSION * MAX_DIMENSION] = {0};
    double rhs[MAX_DIMENSION] = {0};
    double solution[MAX_DIMENSION] = {0};
    double residual[MAX_DIMENSION] = {0};
    double direction[MAX_DIMENSION] = {0};
    double product[MAX_DIMENSION] = {0};
    for (size_t index = 0; index < n * n + n; ++index)
        if (values[index + 1] < -MAX_ENTRY_MICRO || values[index + 1] > MAX_ENTRY_MICRO) return -1;

    for (size_t row = 0; row < n; ++row) {
        const int64_t diagonal = values[1 + row * n + row];
        if (diagonal <= 0) return -1;
        int64_t off_diagonal_sum = 0;
        for (size_t column = 0; column < n; ++column) {
            const int64_t entry = values[1 + row * n + column];
            if (entry != values[1 + column * n + row]) return -1;
            if (column != row) off_diagonal_sum += entry < 0 ? -entry : entry;
            matrix[row * n + column] = (double)entry / SCALE;
        }
        if (diagonal <= off_diagonal_sum) return -1;
        rhs[row] = (double)values[vector_offset + row] / SCALE;
        residual[row] = rhs[row];
        direction[row] = rhs[row];
    }
    const size_t output_bytes = n * 8;
    if (output == NULL || output_capacity < output_bytes) return -2;

    double residual_squared = 0.0;
    for (size_t index = 0; index < n; ++index) residual_squared += residual[index] * residual[index];
    for (size_t iteration = 0; iteration < MAX_ITERATIONS && residual_squared > TOLERANCE * TOLERANCE; ++iteration) {
        for (size_t row = 0; row < n; ++row) {
            product[row] = 0.0;
            for (size_t column = 0; column < n; ++column)
                product[row] += matrix[row * n + column] * direction[column];
        }
        double denominator = 0.0;
        for (size_t index = 0; index < n; ++index) denominator += direction[index] * product[index];
        if (!(denominator > 0.0) || !isfinite(denominator)) return -1;
        const double alpha = residual_squared / denominator;
        for (size_t index = 0; index < n; ++index) {
            solution[index] += alpha * direction[index];
            residual[index] -= alpha * product[index];
        }
        double next_residual_squared = 0.0;
        for (size_t index = 0; index < n; ++index) next_residual_squared += residual[index] * residual[index];
        if (next_residual_squared <= TOLERANCE * TOLERANCE) {
            residual_squared = next_residual_squared;
            break;
        }
        const double beta = next_residual_squared / residual_squared;
        for (size_t index = 0; index < n; ++index)
            direction[index] = residual[index] + beta * direction[index];
        residual_squared = next_residual_squared;
    }
    for (size_t index = 0; index < n; ++index) {
        if (!isfinite(solution[index])) return -1;
        write_f64_le(output, index * 8, solution[index]);
    }
    return (int64_t)output_bytes;
}
