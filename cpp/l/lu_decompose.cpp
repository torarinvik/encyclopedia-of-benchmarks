#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
double rounded_multiply(double left, double right) noexcept {
    volatile double result = left * right;
    return result;
}

double rounded_add(double left, double right) noexcept {
    volatile double result = left + right;
    return result;
}

double rounded_subtract(double left, double right) noexcept {
    volatile double result = left - right;
    return result;
}

double rounded_divide(double left, double right) noexcept {
    volatile double result = left / right;
    return result;
}

bool exact_integer_in_range(double value, std::int64_t minimum, std::int64_t maximum,
                            std::int64_t& integer) noexcept {
    if (!std::isfinite(value) || value < static_cast<double>(minimum) ||
        value > static_cast<double>(maximum)) return false;
    const auto converted = static_cast<std::int64_t>(value);
    if (static_cast<double>(converted) != value) return false;
    integer = converted;
    return true;
}
}

extern "C" std::int64_t lu_decompose(const double* input, std::size_t input_length,
                                     double* output, std::size_t output_capacity) noexcept {
    constexpr std::size_t max_dimension = 4;
    constexpr std::size_t max_parseable_input_length = 18;
    constexpr std::size_t max_output_elements = 32;
    if (input == nullptr || input_length < 1 || input_length > max_parseable_input_length) return -1;

    std::int64_t dimension_value;
    if (!exact_integer_in_range(input[0], 1, static_cast<std::int64_t>(max_dimension), dimension_value)) return -1;
    const auto dimension = static_cast<std::size_t>(dimension_value);
    const std::size_t matrix_elements = dimension * dimension;
    if (input_length != 1 + matrix_elements) return -1;

    double matrix[max_dimension * max_dimension]{};
    for (std::size_t index = 0; index < matrix_elements; ++index) {
        std::int64_t integer;
        if (!exact_integer_in_range(input[index + 1], -8, 8, integer)) return -1;
        matrix[index] = static_cast<double>(integer);
    }

    double lower[max_dimension * max_dimension]{};
    double upper[max_dimension * max_dimension]{};
    for (std::size_t row = 0; row < dimension; ++row) {
        for (std::size_t col = row; col < dimension; ++col) {
            double lu_sum = 0.0;
            for (std::size_t index = 0; index < row; ++index) {
                const double product = rounded_multiply(lower[row * dimension + index],
                                                        upper[index * dimension + col]);
                lu_sum = rounded_add(lu_sum, product);
            }
            upper[row * dimension + col] = rounded_subtract(matrix[row * dimension + col], lu_sum);
            if (!std::isfinite(upper[row * dimension + col])) return -1;
        }

        const double pivot = upper[row * dimension + row];
        if (!std::isfinite(pivot) || pivot == 0.0) return -1;
        for (std::size_t col = row; col < dimension; ++col) {
            if (row == col) {
                lower[row * dimension + col] = 1.0;
                continue;
            }
            double lu_sum = 0.0;
            for (std::size_t index = 0; index < row; ++index) {
                const double product = rounded_multiply(lower[col * dimension + index],
                                                        upper[index * dimension + row]);
                lu_sum = rounded_add(lu_sum, product);
            }
            const double numerator = rounded_subtract(matrix[col * dimension + row], lu_sum);
            const double value = rounded_divide(numerator, pivot);
            if (!std::isfinite(value)) return -1;
            lower[col * dimension + row] = value;
        }
    }

    double staged[max_output_elements]{};
    for (std::size_t index = 0; index < matrix_elements; ++index) {
        if (!std::isfinite(lower[index]) || !std::isfinite(upper[index])) return -1;
        staged[index] = lower[index];
        staged[matrix_elements + index] = upper[index];
    }

    const std::size_t output_length = 2 * matrix_elements;
    if (output == nullptr || output_capacity < output_length) return -2;
    for (std::size_t index = 0; index < output_length; ++index) output[index] = staged[index];
    return static_cast<std::int64_t>(output_length);
}
