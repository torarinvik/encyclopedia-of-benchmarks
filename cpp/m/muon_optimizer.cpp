#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_group_count = 4;
constexpr std::size_t max_rows = 4;
constexpr std::size_t max_columns = 4;
constexpr std::size_t max_matrix_elements = 16;
constexpr std::size_t max_group_matrix_elements = 32;
constexpr std::size_t max_call_count = 8;
constexpr std::size_t max_valid_input_length = 271;
constexpr std::size_t max_parseable_input_length = 272;

double rounded_multiply(double left, double right) noexcept
{
    volatile double result = left * right;
    return result;
}

double rounded_add(double left, double right) noexcept
{
    volatile double result = left + right;
    return result;
}

double rounded_subtract(double left, double right) noexcept
{
    volatile double result = left - right;
    return result;
}

bool exact_bounded_integer(double value, std::size_t minimum, std::size_t maximum,
                           std::size_t &result) noexcept
{
    if (!std::isfinite(value) || value < static_cast<double>(minimum) ||
        value > static_cast<double>(maximum)) return false;
    const std::size_t converted = static_cast<std::size_t>(value);
    if (value != static_cast<double>(converted)) return false;
    result = converted;
    return true;
}

void orthogonalize(const double *gradient, std::size_t rows, std::size_t columns,
                   std::size_t ns_steps, double *result) noexcept
{
    const bool transposed = rows < columns;
    const std::size_t working_rows = transposed ? columns : rows;
    const std::size_t working_columns = transposed ? rows : columns;
    double matrix[max_rows][max_columns]{};

    for (std::size_t row = 0; row < rows; ++row) {
        for (std::size_t column = 0; column < columns; ++column) {
            if (transposed) matrix[column][row] = gradient[row * columns + column];
            else matrix[row][column] = gradient[row * columns + column];
        }
    }

    for (std::size_t step = 0; step < ns_steps; ++step) {
        double gram[max_columns][max_columns]{};
        double product[max_rows][max_columns]{};
        for (std::size_t left = 0; left < working_columns; ++left) {
            for (std::size_t right = 0; right < working_columns; ++right) {
                double sum = 0.0;
                for (std::size_t row = 0; row < working_rows; ++row) {
                    sum = rounded_add(sum, rounded_multiply(matrix[row][left], matrix[row][right]));
                }
                gram[left][right] = sum;
            }
        }
        for (std::size_t row = 0; row < working_rows; ++row) {
            for (std::size_t column = 0; column < working_columns; ++column) {
                double sum = 0.0;
                for (std::size_t inner = 0; inner < working_columns; ++inner) {
                    sum = rounded_add(sum, rounded_multiply(matrix[row][inner], gram[inner][column]));
                }
                product[row][column] = sum;
            }
        }
        for (std::size_t row = 0; row < working_rows; ++row) {
            for (std::size_t column = 0; column < working_columns; ++column) {
                matrix[row][column] = rounded_subtract(
                    rounded_multiply(1.5, matrix[row][column]),
                    rounded_multiply(0.5, product[row][column]));
            }
        }
    }

    for (std::size_t row = 0; row < rows; ++row) {
        for (std::size_t column = 0; column < columns; ++column) {
            result[row * columns + column] = transposed
                ? matrix[column][row]
                : matrix[row][column];
        }
    }
}
}

extern "C" std::int64_t muon_optimizer(const double *input, std::size_t input_length,
                                         double *output, std::size_t output_capacity) noexcept
{
    if (input == nullptr || input_length < 10 || input_length > max_parseable_input_length) return -1;
    for (std::size_t index = 0; index < input_length; ++index) {
        if (!std::isfinite(input[index])) return -1;
    }

    std::size_t group_count, rows, columns, call_count, ns_steps;
    if (!exact_bounded_integer(input[0], 1, max_group_count, group_count) ||
        !exact_bounded_integer(input[1], 1, max_rows, rows) ||
        !exact_bounded_integer(input[2], 1, max_columns, columns) ||
        !exact_bounded_integer(input[3], 1, max_call_count, call_count) ||
        !exact_bounded_integer(input[4], 0, 5, ns_steps)) return -1;

    const std::size_t matrix_elements = rows * columns;
    if (matrix_elements > max_matrix_elements ||
        group_count * matrix_elements > max_group_matrix_elements ||
        call_count < group_count) return -1;
    const std::size_t expected_length = 7 + call_count * (1 + 2 * matrix_elements);
    if (input_length != expected_length || input_length > max_valid_input_length) return -1;

    const double learning_rate = input[5];
    const double momentum = input[6];
    if (learning_rate < 0.0 || learning_rate > 0.25 ||
        momentum < 0.0 || momentum > 0.99) return -1;

    std::size_t ids[max_call_count]{};
    double event_params[max_call_count * max_matrix_elements]{};
    double event_gradients[max_call_count * max_matrix_elements]{};
    bool seen[max_group_count]{};
    std::size_t cursor = 7;
    for (std::size_t event = 0; event < call_count; ++event) {
        std::size_t id;
        if (!exact_bounded_integer(input[cursor], 0, group_count - 1, id)) return -1;
        ids[event] = id;
        seen[id] = true;
        ++cursor;
        for (std::size_t element = 0; element < matrix_elements; ++element) {
            const double value = input[cursor + element];
            if (value < -10.0 || value > 10.0) return -1;
            event_params[event * matrix_elements + element] = value;
        }
        cursor += matrix_elements;
        for (std::size_t element = 0; element < matrix_elements; ++element) {
            const double value = input[cursor + element];
            if (value < -0.01 || value > 0.01) return -1;
            event_gradients[event * matrix_elements + element] = value;
        }
        cursor += matrix_elements;
    }
    for (std::size_t id = 0; id < group_count; ++id) {
        if (!seen[id]) return -1;
    }

    const std::size_t group_elements = group_count * matrix_elements;
    const std::size_t output_elements = 2 * group_elements;
    if (output == nullptr || output_capacity < output_elements) return -2;

    double velocities[max_group_matrix_elements]{};
    double last_params[max_group_matrix_elements]{};
    for (std::size_t event = 0; event < call_count; ++event) {
        const std::size_t id = ids[event];
        const std::size_t state_offset = id * matrix_elements;
        double orthogonalized[max_matrix_elements];
        orthogonalize(&event_gradients[event * matrix_elements], rows, columns,
                      ns_steps, orthogonalized);
        for (std::size_t element = 0; element < matrix_elements; ++element) {
            const std::size_t state_index = state_offset + element;
            const std::size_t event_index = event * matrix_elements + element;
            velocities[state_index] = rounded_add(
                rounded_multiply(momentum, velocities[state_index]), orthogonalized[element]);
            last_params[state_index] = rounded_subtract(
                event_params[event_index],
                rounded_multiply(learning_rate, velocities[state_index]));
        }
    }

    for (std::size_t index = 0; index < group_elements; ++index) {
        output[index] = last_params[index];
        output[group_elements + index] = velocities[index];
    }
    return static_cast<std::int64_t>(output_elements);
}
