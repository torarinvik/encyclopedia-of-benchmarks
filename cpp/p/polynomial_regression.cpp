#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_input_length = 18;
constexpr std::size_t max_training_count = 5;
constexpr std::size_t max_columns = 4;
constexpr std::size_t max_output_elements = 8;

double rounded_add(double left, double right) noexcept
{
    volatile double value = left + right;
    return value;
}

double rounded_subtract(double left, double right) noexcept
{
    volatile double value = left - right;
    return value;
}

double rounded_multiply(double left, double right) noexcept
{
    volatile double value = left * right;
    return value;
}

double rounded_divide(double left, double right) noexcept
{
    volatile double value = left / right;
    return value;
}

bool exact_integer_in_range(double value, std::int64_t minimum, std::int64_t maximum) noexcept
{
    if (!std::isfinite(value) || value < static_cast<double>(minimum) ||
        value > static_cast<double>(maximum)) return false;
    return value == static_cast<double>(static_cast<std::int64_t>(value));
}
} // namespace

extern "C" std::int64_t polynomial_regression(const double* input,
                                              std::size_t input_length,
                                              double* output,
                                              std::size_t output_capacity) noexcept
{
    if (input == nullptr || input_length < 3 || input_length > max_input_length) return -1;
    for (std::size_t i = 0; i < input_length; ++i) {
        if (!std::isfinite(input[i])) return -1;
    }
    if (!exact_integer_in_range(input[0], 0, 3) ||
        !exact_integer_in_range(input[1], 1, static_cast<std::int64_t>(max_training_count)) ||
        !exact_integer_in_range(input[2], 1, 4)) return -1;

    const std::size_t degree = static_cast<std::size_t>(input[0]);
    const std::size_t training_count = static_cast<std::size_t>(input[1]);
    const std::size_t query_count = static_cast<std::size_t>(input[2]);
    const std::size_t columns = degree + 1;
    if (training_count < columns) return -1;
    const std::size_t expected_length = 3 + 2 * training_count + query_count;
    if (input_length != expected_length) return -1;

    double x_train[max_training_count];
    double y_train[max_training_count];
    double x_query[4];
    for (std::size_t row = 0; row < training_count; ++row) {
        const double x = input[3 + row];
        const double y = input[3 + training_count + row];
        if (!exact_integer_in_range(x, -2, 2) || !exact_integer_in_range(y, -32, 32)) return -1;
        x_train[row] = x;
        y_train[row] = y;
    }
    for (std::size_t query = 0; query < query_count; ++query) {
        const double x = input[3 + 2 * training_count + query];
        if (!exact_integer_in_range(x, -2, 2)) return -1;
        x_query[query] = x;
    }
    for (std::size_t row = 0; row < training_count; ++row) {
        for (std::size_t previous = 0; previous < row; ++previous) {
            if (x_train[row] == x_train[previous]) return -1;
        }
    }

    double design[max_training_count * max_columns] = {};
    for (std::size_t row = 0; row < training_count; ++row) {
        double power = 1.0;
        for (std::size_t column = 0; column < columns; ++column) {
            design[row * columns + column] = power;
            power = rounded_multiply(power, x_train[row]);
        }
    }

    double q_matrix[max_training_count * max_columns] = {};
    double r_matrix[max_columns * max_columns] = {};
    for (std::size_t column = 0; column < columns; ++column) {
        double vector[max_training_count] = {};
        for (std::size_t row = 0; row < training_count; ++row) {
            vector[row] = design[row * columns + column];
        }
        for (std::size_t previous = 0; previous < column; ++previous) {
            double dot = 0.0;
            for (std::size_t row = 0; row < training_count; ++row) {
                dot = rounded_add(dot, rounded_multiply(q_matrix[row * columns + previous],
                                                        vector[row]));
            }
            r_matrix[previous * columns + column] = dot;
            for (std::size_t row = 0; row < training_count; ++row) {
                const double projection = rounded_multiply(dot, q_matrix[row * columns + previous]);
                vector[row] = rounded_subtract(vector[row], projection);
            }
        }

        double norm_squared = 0.0;
        for (std::size_t row = 0; row < training_count; ++row) {
            norm_squared = rounded_add(norm_squared, rounded_multiply(vector[row], vector[row]));
        }
        if (!std::isfinite(norm_squared) || norm_squared <= 0.0) return -1;
        const double norm = std::sqrt(norm_squared);
        if (!std::isfinite(norm) || norm <= 0.0) return -1;
        r_matrix[column * columns + column] = norm;
        for (std::size_t row = 0; row < training_count; ++row) {
            q_matrix[row * columns + column] = rounded_divide(vector[row], norm);
        }
    }

    double projected[max_columns] = {};
    for (std::size_t column = 0; column < columns; ++column) {
        for (std::size_t row = 0; row < training_count; ++row) {
            projected[column] = rounded_add(projected[column],
                                            rounded_multiply(q_matrix[row * columns + column],
                                                             y_train[row]));
        }
    }

    double coefficients[max_columns] = {};
    for (std::size_t remaining = columns; remaining > 0; --remaining) {
        const std::size_t column = remaining - 1;
        double value = projected[column];
        for (std::size_t next = column + 1; next < columns; ++next) {
            value = rounded_subtract(value,
                                     rounded_multiply(r_matrix[column * columns + next],
                                                      coefficients[next]));
        }
        const double diagonal = r_matrix[column * columns + column];
        if (!std::isfinite(diagonal) || diagonal == 0.0) return -1;
        coefficients[column] = rounded_divide(value, diagonal);
        if (!std::isfinite(coefficients[column])) return -1;
    }

    double results[max_output_elements] = {};
    for (std::size_t column = 0; column < columns; ++column) results[column] = coefficients[column];
    for (std::size_t query = 0; query < query_count; ++query) {
        double prediction = 0.0;
        double power = 1.0;
        for (std::size_t column = 0; column < columns; ++column) {
            prediction = rounded_add(prediction, rounded_multiply(power, coefficients[column]));
            power = rounded_multiply(power, x_query[query]);
        }
        if (!std::isfinite(prediction)) return -1;
        results[columns + query] = prediction;
    }

    const std::size_t output_length = columns + query_count;
    if (output == nullptr || output_capacity < output_length) return -2;
    for (std::size_t i = 0; i < output_length; ++i) output[i] = results[i];
    return static_cast<std::int64_t>(output_length);
}
