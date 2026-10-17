#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_DIMENSION 4
#define MAX_PARSEABLE_INPUT_LENGTH 18
#define MAX_OUTPUT_ELEMENTS 21

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

static int exact_integer_in_range(double value, int64_t minimum, int64_t maximum,
                                  int64_t *integer)
{
    if (!isfinite(value) || value < (double)minimum || value > (double)maximum) return 0;
    const int64_t converted = (int64_t)value;
    if ((double)converted != value) return 0;
    *integer = converted;
    return 1;
}

int64_t lu_pivot_decomposition(const double *input, size_t input_length,
                               double *output, size_t output_capacity)
{
    if (input == NULL || input_length < 1 || input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1;

    int64_t dimension_value;
    if (!exact_integer_in_range(input[0], 1, MAX_DIMENSION, &dimension_value)) return -1;
    const size_t dimension = (size_t)dimension_value;
    const size_t matrix_elements = dimension * dimension;
    if (input_length != 1 + matrix_elements) return -1;

    double packed_lu[MAX_DIMENSION * MAX_DIMENSION] = {0.0};
    for (size_t index = 0; index < matrix_elements; ++index) {
        int64_t integer;
        if (!exact_integer_in_range(input[index + 1], -8, 8, &integer)) return -1;
        packed_lu[index] = (double)integer;
    }

    int64_t pivot[MAX_DIMENSION + 1] = {0};
    for (size_t index = 0; index <= dimension; ++index) pivot[index] = (int64_t)index;

    for (size_t col = 0; col < dimension; ++col) {
        double max_value = 0.0;
        size_t max_index = col;
        for (size_t row = col; row < dimension; ++row) {
            const double entry = packed_lu[row * dimension + col];
            const double magnitude = entry < 0.0 ? -entry : entry;
            if (magnitude > max_value) {
                max_value = magnitude;
                max_index = row;
            }
        }

        if (max_index != col) {
            for (size_t index = 0; index < dimension; ++index) {
                const double temporary = packed_lu[col * dimension + index];
                packed_lu[col * dimension + index] = packed_lu[max_index * dimension + index];
                packed_lu[max_index * dimension + index] = temporary;
            }
            const int64_t temporary = pivot[col];
            pivot[col] = pivot[max_index];
            pivot[max_index] = temporary;
            pivot[dimension]++;
        }

        const double pivot_value = packed_lu[col * dimension + col];
        if (!isfinite(pivot_value) || pivot_value == 0.0) return -1;

        for (size_t row = col + 1; row < dimension; ++row) {
            const double multiplier = rounded_divide(packed_lu[row * dimension + col], pivot_value);
            if (!isfinite(multiplier)) return -1;
            packed_lu[row * dimension + col] = multiplier;

            for (size_t trailing_col = col + 1; trailing_col < dimension; ++trailing_col) {
                const double product = rounded_multiply(multiplier,
                                                        packed_lu[col * dimension + trailing_col]);
                const double value = rounded_subtract(packed_lu[row * dimension + trailing_col], product);
                if (!isfinite(value)) return -1;
                packed_lu[row * dimension + trailing_col] = value;
            }
        }
    }

    double staged[MAX_OUTPUT_ELEMENTS];
    for (size_t index = 0; index < matrix_elements; ++index) {
        if (!isfinite(packed_lu[index])) return -1;
        staged[index] = packed_lu[index];
    }
    const size_t output_length = matrix_elements + dimension + 1;
    for (size_t index = 0; index <= dimension; ++index)
        staged[matrix_elements + index] = (double)pivot[index];

    if (output == NULL || output_capacity < output_length) return -2;
    for (size_t index = 0; index < output_length; ++index) output[index] = staged[index];
    return (int64_t)output_length;
}
