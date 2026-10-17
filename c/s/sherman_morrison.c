#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MIN_DIMENSION 1u
#define MAX_DIMENSION 4u
#define MAX_VALID_INPUT_LENGTH 25u
#define MAX_PARSEABLE_INPUT_LENGTH 26u
#define MAX_OUTPUT_ELEMENTS 16u

static double rounded_add(double left, double right)
{
    volatile double value = left + right;
    return value;
}

static double rounded_subtract(double left, double right)
{
    volatile double value = left - right;
    return value;
}

static double rounded_multiply(double left, double right)
{
    volatile double value = left * right;
    return value;
}

static double rounded_divide(double left, double right)
{
    volatile double value = left / right;
    return value;
}

static int exact_integer_in_range(double value, int minimum, int maximum)
{
    if (!isfinite(value) || value < (double)minimum || value > (double)maximum) return 0;
    return value == (double)(int)value;
}

int64_t sherman_morrison(const double *input, size_t input_length,
                         double *output, size_t output_capacity)
{
    if (input == NULL || input_length == 0u ||
        input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    for (size_t i = 0u; i < input_length; ++i) {
        if (!isfinite(input[i])) return -1;
    }

    if (!exact_integer_in_range(input[0], (int)MIN_DIMENSION, (int)MAX_DIMENSION)) return -1;
    const size_t dimension = (size_t)input[0];
    const size_t matrix_size = dimension * dimension;
    const size_t expected_length = 1u + matrix_size + 2u * dimension;
    if (input_length != expected_length) return -1;

    for (size_t i = 1u; i < input_length; ++i) {
        if (!exact_integer_in_range(input[i], -2, 2)) return -1;
    }

    double inverse[MAX_OUTPUT_ELEMENTS] = {0.0};
    double u[MAX_DIMENSION] = {0.0};
    double v[MAX_DIMENSION] = {0.0};
    for (size_t i = 0u; i < matrix_size; ++i) inverse[i] = input[1u + i];
    for (size_t i = 0u; i < dimension; ++i) {
        u[i] = input[1u + matrix_size + i];
        v[i] = input[1u + matrix_size + dimension + i];
    }

    /* Preserve the source's left-associated (v^T * A_inverse) * u order. */
    double right_vector[MAX_DIMENSION] = {0.0};
    for (size_t column = 0u; column < dimension; ++column) {
        double sum = 0.0;
        for (size_t inner = 0u; inner < dimension; ++inner) {
            sum = rounded_add(sum,
                              rounded_multiply(v[inner], inverse[inner * dimension + column]));
        }
        right_vector[column] = sum;
    }

    double denominator_term = 0.0;
    for (size_t inner = 0u; inner < dimension; ++inner) {
        denominator_term = rounded_add(denominator_term,
                                       rounded_multiply(right_vector[inner], u[inner]));
    }
    const double denominator = rounded_add(1.0, denominator_term);
    const int singular = denominator == 0.0;

    double results[MAX_OUTPUT_ELEMENTS] = {0.0};
    if (!singular) {
        double left_vector[MAX_DIMENSION] = {0.0};
        for (size_t row = 0u; row < dimension; ++row) {
            double sum = 0.0;
            for (size_t inner = 0u; inner < dimension; ++inner) {
                sum = rounded_add(sum,
                                  rounded_multiply(inverse[row * dimension + inner], u[inner]));
            }
            left_vector[row] = sum;
        }

        const double reciprocal = rounded_divide(1.0, denominator);
        for (size_t row = 0u; row < dimension; ++row) {
            for (size_t column = 0u; column < dimension; ++column) {
                const double outer_product = rounded_multiply(left_vector[row], right_vector[column]);
                const double correction = rounded_multiply(outer_product, reciprocal);
                results[row * dimension + column] =
                    rounded_subtract(inverse[row * dimension + column], correction);
            }
        }
    }

    /* Null output is an ABI error even when the source result is None. */
    if (output == NULL) return -2;
    if (singular) return 0;

    const size_t output_length = matrix_size;
    if (output_capacity < output_length) return -2;
    for (size_t i = 0u; i < output_length; ++i) output[i] = results[i];
    return (int64_t)output_length;
}
