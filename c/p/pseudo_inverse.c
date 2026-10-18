#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_ROWS 4u
#define MAX_INPUT_LENGTH 7u
#define SINGULAR_VALUE_CUTOFF 1e-4

static int integer_in_range(double value, int minimum, int maximum) {
    return isfinite(value) && value >= (double)minimum && value <= (double)maximum && value == trunc(value);
}

int64_t pseudo_inverse(const double *input, size_t input_length,
                       double *output, size_t output_capacity) {
    if (input == NULL || input_length < 3u || input_length > MAX_INPUT_LENGTH) return -1;
    for (size_t index = 0; index < input_length; ++index) {
        if (!isfinite(input[index])) return -1;
    }
    if (!integer_in_range(input[0], 1, (int)MAX_ROWS) || !integer_in_range(input[1], 1, 1)) return -1;
    const size_t row_count = (size_t)input[0];
    const size_t column_count = (size_t)input[1];
    if (input_length != 2u + row_count * column_count || input_length > 2u + MAX_ROWS) return -1;

    double column[MAX_ROWS];
    double squared_norm = 0.0;
    for (size_t row = 0; row < row_count; ++row) {
        const double value = input[2 + row];
        if (value < -4.0 || value > 4.0 || value != trunc(value)) return -1;
        column[row] = value;
        squared_norm += value * value;
    }
    const double singular_value = sqrt(squared_norm);
    double staged[2 + MAX_ROWS];
    staged[0] = 1.0;
    staged[1] = (double)row_count;
    for (size_t row = 0; row < row_count; ++row) {
        staged[2 + row] = fabs(singular_value) < SINGULAR_VALUE_CUTOFF
            ? 0.0 : column[row] / squared_norm;
    }

    const size_t result_length = 2u + row_count;
    if (output == NULL || output_capacity < result_length) return -2;
    for (size_t index = 0; index < result_length; ++index) output[index] = staged[index];
    return (int64_t)result_length;
}
