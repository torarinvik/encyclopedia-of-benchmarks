#include <math.h>
#include <stddef.h>
#include <stdint.h>
#include <string.h>

#define MAX_INPUT_VALUES 11
#define MAX_OUTPUT_BYTES 72
#define INVALID_RESULT (-1)
#define OUTPUT_ERROR (-2)
#define COEFFICIENT_LIMIT 32
#define COEFFICIENT_SCALE 16.0

static double rounded_multiply(double left, double right)
{
    volatile double result = left * right;
    return result;
}

static double rounded_subtract(double left, double right)
{
    volatile double result = left - right;
    return result;
}

static double rounded_divide(double left, double right)
{
    volatile double result = left / right;
    return result;
}

static int64_t absolute_coefficient(int64_t value)
{
    return value < 0 ? -value : value;
}

static int valid_dominance(const int64_t *matrix, size_t dimension)
{
    int dominant_column[3] = {-1, -1, -1};
    int column_seen[3] = {0, 0, 0};
    for (size_t row = 0; row < dimension; ++row) {
        for (size_t column = 0; column < dimension; ++column) {
            int64_t other_sum = 0;
            for (size_t other = 0; other < dimension; ++other) {
                if (other != column)
                    other_sum += absolute_coefficient(matrix[row * dimension + other]);
            }
            if (absolute_coefficient(matrix[row * dimension + column]) > other_sum) {
                if (dominant_column[row] != -1) return 0;
                dominant_column[row] = (int)column;
            }
        }
        if (dominant_column[row] == -1 || column_seen[dominant_column[row]]) return 0;
        column_seen[dominant_column[row]] = 1;
    }
    return 1;
}

static int scaled_pivot_inverse(const double *matrix, size_t dimension,
                               double *inverse)
{
    double a[9] = {0.0};
    double b[9] = {0.0};
    double scale[3] = {0.0};
    int index[3] = {0, 1, 2};
    for (size_t row = 0; row < dimension; ++row) {
        for (size_t column = 0; column < dimension; ++column) {
            a[row * dimension + column] = matrix[row * dimension + column];
            if (row == column) b[row * dimension + column] = 1.0;
            const double magnitude = fabs(a[row * dimension + column]);
            if (magnitude > scale[row]) scale[row] = magnitude;
        }
        if (scale[row] == 0.0) return 0;
    }

    for (size_t column = 0; column + 1 < dimension; ++column) {
        double best_ratio = 0.0;
        size_t best = column;
        for (size_t row = column; row < dimension; ++row) {
            const double ratio = rounded_divide(
                fabs(a[(size_t)index[row] * dimension + column]),
                scale[index[row]]);
            if (ratio > best_ratio) {
                best_ratio = ratio;
                best = row;
            }
        }

        const int temporary = index[column];
        index[column] = index[best];
        index[best] = temporary;
        const size_t pivot_row = (size_t)index[column];
        const double pivot = a[pivot_row * dimension + column];
        if (pivot == 0.0) return 0;

        for (size_t row = column + 1; row < dimension; ++row) {
            const size_t current_row = (size_t)index[row];
            const double factor = rounded_divide(
                a[current_row * dimension + column], pivot);
            a[current_row * dimension + column] = factor;
            for (size_t trailing = column + 1; trailing < dimension; ++trailing) {
                const double product = rounded_multiply(
                    factor, a[pivot_row * dimension + trailing]);
                a[current_row * dimension + trailing] = rounded_subtract(
                    a[current_row * dimension + trailing], product);
            }
        }
    }

    for (size_t row = 0; row + 1 < dimension; ++row) {
        const size_t current_row = (size_t)index[row];
        for (size_t lower = row + 1; lower < dimension; ++lower) {
            const size_t lower_row = (size_t)index[lower];
            for (size_t column = 0; column < dimension; ++column) {
                const double product = rounded_multiply(
                    a[lower_row * dimension + row],
                    b[current_row * dimension + column]);
                b[lower_row * dimension + column] = rounded_subtract(
                    b[lower_row * dimension + column], product);
            }
        }
    }

    for (size_t column = 0; column < dimension; ++column) {
        const size_t last_row = (size_t)index[dimension - 1];
        const double last_pivot = a[last_row * dimension + dimension - 1];
        if (last_pivot == 0.0) return 0;
        inverse[(dimension - 1) * dimension + column] = rounded_divide(
            b[last_row * dimension + column], last_pivot);

        for (size_t step = dimension - 1; step-- > 0;) {
            const size_t current_row = (size_t)index[step];
            double value = b[current_row * dimension + column];
            for (size_t trailing = step + 1; trailing < dimension; ++trailing) {
                const double product = rounded_multiply(
                    a[current_row * dimension + trailing],
                    inverse[trailing * dimension + column]);
                value = rounded_subtract(value, product);
            }
            const double pivot = a[current_row * dimension + step];
            if (pivot == 0.0) return 0;
            inverse[step * dimension + column] = rounded_divide(value, pivot);
        }
    }

    for (size_t i = 0; i < dimension * dimension; ++i) {
        if (!isfinite(inverse[i])) return 0;
    }
    return 1;
}

static void store_little_endian_double(uint8_t *output, double value)
{
    uint64_t bits;
    memcpy(&bits, &value, sizeof(bits));
    for (size_t byte = 0; byte < 8; ++byte)
        output[byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t inverse_of_matrix(const int64_t *input, size_t input_length,
                          uint8_t *output, size_t output_capacity)
{
    if (input == NULL || input_length < 1 || input_length > MAX_INPUT_VALUES)
        return INVALID_RESULT;
    if (input[0] != 2 && input[0] != 3) return INVALID_RESULT;
    const size_t dimension = (size_t)input[0];
    if (input_length != 1 + dimension * dimension) return INVALID_RESULT;

    int64_t matrix_q[9] = {0};
    double matrix[9] = {0.0};
    for (size_t index = 0; index < dimension * dimension; ++index) {
        const int64_t value = input[index + 1];
        if (value < -COEFFICIENT_LIMIT || value > COEFFICIENT_LIMIT)
            return INVALID_RESULT;
        matrix_q[index] = value;
        matrix[index] = (double)value / COEFFICIENT_SCALE;
    }
    if (!valid_dominance(matrix_q, dimension)) return INVALID_RESULT;

    double inverse[9] = {0.0};
    if (!scaled_pivot_inverse(matrix, dimension, inverse)) return INVALID_RESULT;

    const size_t output_bytes = dimension * dimension * 8;
    uint8_t encoded[MAX_OUTPUT_BYTES];
    for (size_t index = 0; index < dimension * dimension; ++index)
        store_little_endian_double(encoded + index * 8, inverse[index]);

    if (output == NULL || output_capacity < output_bytes) return OUTPUT_ERROR;
    memcpy(output, encoded, output_bytes);
    return (int64_t)output_bytes;
}
