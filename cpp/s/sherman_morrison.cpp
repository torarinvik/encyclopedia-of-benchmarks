#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t min_dimension = 1;
constexpr std::size_t max_dimension = 4;
constexpr std::size_t max_parseable_input_length = 26;
constexpr std::size_t max_output_elements = 16;

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

bool exact_integer_in_range(double value, int minimum, int maximum) noexcept
{
    if (!std::isfinite(value) || value < static_cast<double>(minimum) ||
        value > static_cast<double>(maximum)) return false;
    return value == static_cast<double>(static_cast<int>(value));
}
} // namespace

extern "C" std::int64_t sherman_morrison(const double* input,
                                          std::size_t input_length,
                                          double* output,
                                          std::size_t output_capacity) noexcept
{
    if (input == nullptr || input_length == 0 ||
        input_length > max_parseable_input_length) return -1;
    for (std::size_t i = 0; i < input_length; ++i) {
        if (!std::isfinite(input[i])) return -1;
    }

    if (!exact_integer_in_range(input[0], static_cast<int>(min_dimension),
                                static_cast<int>(max_dimension))) return -1;
    const std::size_t dimension = static_cast<std::size_t>(input[0]);
    const std::size_t matrix_size = dimension * dimension;
    const std::size_t expected_length = 1 + matrix_size + 2 * dimension;
    if (input_length != expected_length) return -1;

    for (std::size_t i = 1; i < input_length; ++i) {
        if (!exact_integer_in_range(input[i], -2, 2)) return -1;
    }

    double inverse[max_output_elements] = {};
    double u[max_dimension] = {};
    double v[max_dimension] = {};
    for (std::size_t i = 0; i < matrix_size; ++i) inverse[i] = input[1 + i];
    for (std::size_t i = 0; i < dimension; ++i) {
        u[i] = input[1 + matrix_size + i];
        v[i] = input[1 + matrix_size + dimension + i];
    }

    /* Preserve the source's left-associated (v^T * A_inverse) * u order. */
    double right_vector[max_dimension] = {};
    for (std::size_t column = 0; column < dimension; ++column) {
        double sum = 0.0;
        for (std::size_t inner = 0; inner < dimension; ++inner) {
            sum = rounded_add(sum,
                              rounded_multiply(v[inner], inverse[inner * dimension + column]));
        }
        right_vector[column] = sum;
    }

    double denominator_term = 0.0;
    for (std::size_t inner = 0; inner < dimension; ++inner) {
        denominator_term = rounded_add(denominator_term,
                                       rounded_multiply(right_vector[inner], u[inner]));
    }
    const double denominator = rounded_add(1.0, denominator_term);
    const bool singular = denominator == 0.0;

    double results[max_output_elements] = {};
    if (!singular) {
        double left_vector[max_dimension] = {};
        for (std::size_t row = 0; row < dimension; ++row) {
            double sum = 0.0;
            for (std::size_t inner = 0; inner < dimension; ++inner) {
                sum = rounded_add(sum,
                                  rounded_multiply(inverse[row * dimension + inner], u[inner]));
            }
            left_vector[row] = sum;
        }

        const double reciprocal = rounded_divide(1.0, denominator);
        for (std::size_t row = 0; row < dimension; ++row) {
            for (std::size_t column = 0; column < dimension; ++column) {
                const double outer_product = rounded_multiply(left_vector[row], right_vector[column]);
                const double correction = rounded_multiply(outer_product, reciprocal);
                results[row * dimension + column] =
                    rounded_subtract(inverse[row * dimension + column], correction);
            }
        }
    }

    /* Null output is an ABI error even when the source result is None. */
    if (output == nullptr) return -2;
    if (singular) return 0;

    const std::size_t output_length = matrix_size;
    if (output_capacity < output_length) return -2;
    for (std::size_t i = 0; i < output_length; ++i) output[i] = results[i];
    return static_cast<std::int64_t>(output_length);
}
