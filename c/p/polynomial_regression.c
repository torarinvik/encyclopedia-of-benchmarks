#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_INPUT_LENGTH 18u
#define MAX_TRAINING_COUNT 5u
#define MAX_COLUMNS 4u
#define MAX_OUTPUT_ELEMENTS 8u

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

static int exact_integer_in_range(double value, int64_t minimum, int64_t maximum)
{
    if (!isfinite(value) || value < (double)minimum || value > (double)maximum) return 0;
    return value == (double)(int64_t)value;
}

int64_t polynomial_regression(const double *input, size_t input_length,
                              double *output, size_t output_capacity)
{
    if (input == NULL || input_length < 3u || input_length > MAX_INPUT_LENGTH) return -1;
    for (size_t i = 0u; i < input_length; ++i) {
        if (!isfinite(input[i])) return -1;
    }

    if (!exact_integer_in_range(input[0], 0, 3) ||
        !exact_integer_in_range(input[1], 1, (int64_t)MAX_TRAINING_COUNT) ||
        !exact_integer_in_range(input[2], 1, 4)) return -1;

    const size_t degree = (size_t)input[0];
    const size_t training_count = (size_t)input[1];
    const size_t query_count = (size_t)input[2];
    const size_t columns = degree + 1u;
    if (training_count < columns) return -1;
    const size_t expected_length = 3u + 2u * training_count + query_count;
    if (input_length != expected_length) return -1;

    double x_train[MAX_TRAINING_COUNT];
    double y_train[MAX_TRAINING_COUNT];
    double x_query[4];
    for (size_t row = 0u; row < training_count; ++row) {
        const double x = input[3u + row];
        const double y = input[3u + training_count + row];
        if (!exact_integer_in_range(x, -2, 2) || !exact_integer_in_range(y, -32, 32)) return -1;
        x_train[row] = x;
        y_train[row] = y;
    }
    for (size_t query = 0u; query < query_count; ++query) {
        const double x = input[3u + 2u * training_count + query];
        if (!exact_integer_in_range(x, -2, 2)) return -1;
        x_query[query] = x;
    }
    for (size_t row = 0u; row < training_count; ++row) {
        for (size_t previous = 0u; previous < row; ++previous) {
            if (x_train[row] == x_train[previous]) return -1;
        }
    }

    /* Modified Gram-Schmidt QR keeps the bounded Vandermonde fit stable. */
    double design[MAX_TRAINING_COUNT * MAX_COLUMNS] = {0.0};
    for (size_t row = 0u; row < training_count; ++row) {
        double power = 1.0;
        for (size_t column = 0u; column < columns; ++column) {
            design[row * columns + column] = power;
            power = rounded_multiply(power, x_train[row]);
        }
    }

    double q_matrix[MAX_TRAINING_COUNT * MAX_COLUMNS] = {0.0};
    double r_matrix[MAX_COLUMNS * MAX_COLUMNS] = {0.0};
    for (size_t column = 0u; column < columns; ++column) {
        double vector[MAX_TRAINING_COUNT] = {0.0};
        for (size_t row = 0u; row < training_count; ++row) {
            vector[row] = design[row * columns + column];
        }

        for (size_t previous = 0u; previous < column; ++previous) {
            double dot = 0.0;
            for (size_t row = 0u; row < training_count; ++row) {
                dot = rounded_add(dot, rounded_multiply(q_matrix[row * columns + previous],
                                                        vector[row]));
            }
            r_matrix[previous * columns + column] = dot;
            for (size_t row = 0u; row < training_count; ++row) {
                const double projection = rounded_multiply(dot, q_matrix[row * columns + previous]);
                vector[row] = rounded_subtract(vector[row], projection);
            }
        }

        double norm_squared = 0.0;
        for (size_t row = 0u; row < training_count; ++row) {
            norm_squared = rounded_add(norm_squared, rounded_multiply(vector[row], vector[row]));
        }
        if (!isfinite(norm_squared) || norm_squared <= 0.0) return -1;
        const double norm = sqrt(norm_squared);
        if (!isfinite(norm) || norm <= 0.0) return -1;
        r_matrix[column * columns + column] = norm;
        for (size_t row = 0u; row < training_count; ++row) {
            q_matrix[row * columns + column] = rounded_divide(vector[row], norm);
        }
    }

    double projected[MAX_COLUMNS] = {0.0};
    for (size_t column = 0u; column < columns; ++column) {
        for (size_t row = 0u; row < training_count; ++row) {
            projected[column] = rounded_add(projected[column],
                                            rounded_multiply(q_matrix[row * columns + column],
                                                             y_train[row]));
        }
    }

    double coefficients[MAX_COLUMNS] = {0.0};
    for (size_t remaining = columns; remaining > 0u; --remaining) {
        const size_t column = remaining - 1u;
        double value = projected[column];
        for (size_t next = column + 1u; next < columns; ++next) {
            value = rounded_subtract(value,
                                    rounded_multiply(r_matrix[column * columns + next],
                                                     coefficients[next]));
        }
        const double diagonal = r_matrix[column * columns + column];
        if (!isfinite(diagonal) || diagonal == 0.0) return -1;
        coefficients[column] = rounded_divide(value, diagonal);
        if (!isfinite(coefficients[column])) return -1;
    }

    double results[MAX_OUTPUT_ELEMENTS] = {0.0};
    for (size_t column = 0u; column < columns; ++column) results[column] = coefficients[column];
    for (size_t query = 0u; query < query_count; ++query) {
        double prediction = 0.0;
        double power = 1.0;
        for (size_t column = 0u; column < columns; ++column) {
            prediction = rounded_add(prediction, rounded_multiply(power, coefficients[column]));
            power = rounded_multiply(power, x_query[query]);
        }
        if (!isfinite(prediction)) return -1;
        results[columns + query] = prediction;
    }

    const size_t output_length = columns + query_count;
    if (output == NULL || output_capacity < output_length) return -2;
    for (size_t i = 0u; i < output_length; ++i) output[i] = results[i];
    return (int64_t)output_length;
}
