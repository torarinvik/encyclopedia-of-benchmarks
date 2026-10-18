/* Solve a bounded square system with the pinned no-pivot LU update order. */
#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_DIMENSION 4
#define MAX_PARSEABLE_INPUT_LENGTH 22

static double rounded_multiply(double left, double right)
{
    volatile double result = left * right;
    return result;
}

static double rounded_add(double left, double right)
{
    volatile double result = left + right;
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

static int exact_integer_in_range(double value, int64_t minimum, int64_t maximum,
                                  int64_t *integer)
{
    if (!isfinite(value) || value < (double)minimum || value > (double)maximum) return 0;
    const int64_t converted = (int64_t)value;
    if ((double)converted != value) return 0;
    *integer = converted;
    return 1;
}

int64_t lu_elimination(const double *input, size_t input_length,
                       double *output, size_t output_capacity)
{
    if (input == NULL || input_length < 1 || input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1;

    int64_t dimension_value;
    if (!exact_integer_in_range(input[0], 0, MAX_DIMENSION, &dimension_value)) return -1;
    const size_t dimension = (size_t)dimension_value;
    const size_t matrix_elements = dimension * dimension;
    const size_t expected_length = 1 + matrix_elements + dimension;
    if (input_length != expected_length) return -1;

    double matrix[MAX_DIMENSION * MAX_DIMENSION] = {0.0};
    double rhs[MAX_DIMENSION] = {0.0};
    for (size_t index = 0; index < matrix_elements; ++index) {
        int64_t integer;
        if (!exact_integer_in_range(input[index + 1], -1, 1, &integer)) return -1;
        matrix[index] = (double)integer;
    }
    for (size_t index = 0; index < dimension; ++index) {
        int64_t integer;
        if (!exact_integer_in_range(input[1 + matrix_elements + index], -8, 8, &integer)) return -1;
        rhs[index] = (double)integer;
    }

    double lower[MAX_DIMENSION * MAX_DIMENSION] = {0.0};
    double upper[MAX_DIMENSION * MAX_DIMENSION] = {0.0};
    for (size_t row = 0; row < dimension; ++row) {
        for (size_t col = row; col < dimension; ++col) {
            double sum = 0.0;
            for (size_t index = 0; index < row; ++index) {
                const double product = rounded_multiply(lower[row * dimension + index],
                                                        upper[index * dimension + col]);
                sum = rounded_add(sum, product);
            }
            upper[row * dimension + col] = rounded_subtract(matrix[row * dimension + col], sum);
            if (!isfinite(upper[row * dimension + col])) return -1;
        }

        const double pivot = upper[row * dimension + row];
        if (!isfinite(pivot) || pivot == 0.0) return -1;
        for (size_t col = row; col < dimension; ++col) {
            if (row == col) {
                lower[row * dimension + col] = 1.0;
                continue;
            }
            double sum = 0.0;
            for (size_t index = 0; index < row; ++index) {
                const double product = rounded_multiply(lower[col * dimension + index],
                                                        upper[index * dimension + row]);
                sum = rounded_add(sum, product);
            }
            const double numerator = rounded_subtract(matrix[col * dimension + row], sum);
            const double value = rounded_divide(numerator, pivot);
            if (!isfinite(value)) return -1;
            lower[col * dimension + row] = value;
        }
    }

    double upper_transform[MAX_DIMENSION] = {0.0};
    for (size_t row = 0; row < dimension; ++row) {
        double sum = 0.0;
        for (size_t col = 0; col < row; ++col) {
            const double product = rounded_multiply(upper_transform[col], lower[row * dimension + col]);
            sum = rounded_add(sum, product);
        }
        const double numerator = rounded_subtract(rhs[row], sum);
        upper_transform[row] = rounded_divide(numerator, lower[row * dimension + row]);
        if (!isfinite(upper_transform[row])) return -1;
    }

    double solution[MAX_DIMENSION] = {0.0};
    for (size_t remaining = dimension; remaining > 0; --remaining) {
        const size_t row = remaining - 1;
        double sum = 0.0;
        for (size_t col = row; col < dimension; ++col) {
            const double product = rounded_multiply(solution[col], upper[row * dimension + col]);
            sum = rounded_add(sum, product);
        }
        const double pivot = upper[row * dimension + row];
        if (!isfinite(pivot) || pivot == 0.0) return -1;
        const double numerator = rounded_subtract(upper_transform[row], sum);
        solution[row] = rounded_divide(numerator, pivot);
        if (!isfinite(solution[row])) return -1;
    }

    if (output == NULL || output_capacity < dimension) return -2;
    for (size_t index = 0; index < dimension; ++index) output[index] = solution[index];
    return (int64_t)dimension;
}
