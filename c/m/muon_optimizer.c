#include <math.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_GROUP_COUNT 4
#define MAX_ROWS 4
#define MAX_COLUMNS 4
#define MAX_MATRIX_ELEMENTS 16
#define MAX_GROUP_MATRIX_ELEMENTS 32
#define MAX_CALL_COUNT 8
#define MAX_VALID_INPUT_LENGTH 271
#define MAX_PARSEABLE_INPUT_LENGTH 272

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

static bool exact_bounded_integer(double value, size_t minimum, size_t maximum,
                                  size_t *result)
{
    if (!isfinite(value) || value < (double)minimum || value > (double)maximum) return false;
    const size_t converted = (size_t)value;
    if (value != (double)converted) return false;
    *result = converted;
    return true;
}

static void orthogonalize(const double *gradient, size_t rows, size_t columns,
                          size_t ns_steps, double *result)
{
    const bool transposed = rows < columns;
    const size_t working_rows = transposed ? columns : rows;
    const size_t working_columns = transposed ? rows : columns;
    double matrix[MAX_ROWS][MAX_COLUMNS] = { { 0.0 } };

    for (size_t row = 0; row < rows; ++row) {
        for (size_t column = 0; column < columns; ++column) {
            if (transposed) matrix[column][row] = gradient[row * columns + column];
            else matrix[row][column] = gradient[row * columns + column];
        }
    }

    for (size_t step = 0; step < ns_steps; ++step) {
        double gram[MAX_COLUMNS][MAX_COLUMNS] = { { 0.0 } };
        double product[MAX_ROWS][MAX_COLUMNS] = { { 0.0 } };
        for (size_t left = 0; left < working_columns; ++left) {
            for (size_t right = 0; right < working_columns; ++right) {
                double sum = 0.0;
                for (size_t row = 0; row < working_rows; ++row) {
                    sum = rounded_add(sum, rounded_multiply(matrix[row][left], matrix[row][right]));
                }
                gram[left][right] = sum;
            }
        }
        for (size_t row = 0; row < working_rows; ++row) {
            for (size_t column = 0; column < working_columns; ++column) {
                double sum = 0.0;
                for (size_t inner = 0; inner < working_columns; ++inner) {
                    sum = rounded_add(sum, rounded_multiply(matrix[row][inner], gram[inner][column]));
                }
                product[row][column] = sum;
            }
        }
        for (size_t row = 0; row < working_rows; ++row) {
            for (size_t column = 0; column < working_columns; ++column) {
                matrix[row][column] = rounded_subtract(
                    rounded_multiply(1.5, matrix[row][column]),
                    rounded_multiply(0.5, product[row][column]));
            }
        }
    }

    for (size_t row = 0; row < rows; ++row) {
        for (size_t column = 0; column < columns; ++column) {
            result[row * columns + column] = transposed
                ? matrix[column][row]
                : matrix[row][column];
        }
    }
}

int64_t muon_optimizer(const double *input, size_t input_length,
                       double *output, size_t output_capacity)
{
    if (input == NULL || input_length < 10 || input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    for (size_t index = 0; index < input_length; ++index) {
        if (!isfinite(input[index])) return -1;
    }

    size_t group_count, rows, columns, call_count, ns_steps;
    if (!exact_bounded_integer(input[0], 1, MAX_GROUP_COUNT, &group_count) ||
        !exact_bounded_integer(input[1], 1, MAX_ROWS, &rows) ||
        !exact_bounded_integer(input[2], 1, MAX_COLUMNS, &columns) ||
        !exact_bounded_integer(input[3], 1, MAX_CALL_COUNT, &call_count) ||
        !exact_bounded_integer(input[4], 0, 5, &ns_steps)) return -1;

    const size_t matrix_elements = rows * columns;
    if (matrix_elements > MAX_MATRIX_ELEMENTS ||
        group_count * matrix_elements > MAX_GROUP_MATRIX_ELEMENTS ||
        call_count < group_count) return -1;
    const size_t expected_length = 7 + call_count * (1 + 2 * matrix_elements);
    if (input_length != expected_length || input_length > MAX_VALID_INPUT_LENGTH) return -1;

    const double learning_rate = input[5];
    const double momentum = input[6];
    if (learning_rate < 0.0 || learning_rate > 0.25 ||
        momentum < 0.0 || momentum > 0.99) return -1;

    size_t ids[MAX_CALL_COUNT] = { 0 };
    double event_params[MAX_CALL_COUNT * MAX_MATRIX_ELEMENTS] = { 0.0 };
    double event_gradients[MAX_CALL_COUNT * MAX_MATRIX_ELEMENTS] = { 0.0 };
    bool seen[MAX_GROUP_COUNT] = { false };
    size_t cursor = 7;
    for (size_t event = 0; event < call_count; ++event) {
        size_t id;
        if (!exact_bounded_integer(input[cursor], 0, group_count - 1, &id)) return -1;
        ids[event] = id;
        seen[id] = true;
        ++cursor;
        for (size_t element = 0; element < matrix_elements; ++element) {
            const double value = input[cursor + element];
            if (value < -10.0 || value > 10.0) return -1;
            event_params[event * matrix_elements + element] = value;
        }
        cursor += matrix_elements;
        for (size_t element = 0; element < matrix_elements; ++element) {
            const double value = input[cursor + element];
            if (value < -0.01 || value > 0.01) return -1;
            event_gradients[event * matrix_elements + element] = value;
        }
        cursor += matrix_elements;
    }
    for (size_t id = 0; id < group_count; ++id) {
        if (!seen[id]) return -1;
    }

    const size_t group_elements = group_count * matrix_elements;
    const size_t output_elements = 2 * group_elements;
    if (output == NULL || output_capacity < output_elements) return -2;

    double velocities[MAX_GROUP_MATRIX_ELEMENTS] = { 0.0 };
    double last_params[MAX_GROUP_MATRIX_ELEMENTS] = { 0.0 };
    for (size_t event = 0; event < call_count; ++event) {
        const size_t id = ids[event];
        const size_t state_offset = id * matrix_elements;
        double orthogonalized[MAX_MATRIX_ELEMENTS];
        orthogonalize(&event_gradients[event * matrix_elements], rows, columns,
                      ns_steps, orthogonalized);
        for (size_t element = 0; element < matrix_elements; ++element) {
            const size_t state_index = state_offset + element;
            const size_t event_index = event * matrix_elements + element;
            velocities[state_index] = rounded_add(
                rounded_multiply(momentum, velocities[state_index]), orthogonalized[element]);
            last_params[state_index] = rounded_subtract(
                event_params[event_index],
                rounded_multiply(learning_rate, velocities[state_index]));
        }
    }

    for (size_t index = 0; index < group_elements; ++index) {
        output[index] = last_params[index];
        output[group_elements + index] = velocities[index];
    }
    return (int64_t)output_elements;
}
