/* Solve a bounded square system with the pinned no-pivot LU update order. */
#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_dimension = 4;
constexpr std::size_t max_parseable_input_length = 22;

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

extern "C" std::int64_t lu_elimination(const double* input, std::size_t input_length,
                                       double* output, std::size_t output_capacity) noexcept {
    if (input == nullptr || input_length < 1 || input_length > max_parseable_input_length) return -1;

    std::int64_t dimension_value;
    if (!exact_integer_in_range(input[0], 0, static_cast<std::int64_t>(max_dimension), dimension_value))
        return -1;
    const auto dimension = static_cast<std::size_t>(dimension_value);
    const std::size_t matrix_elements = dimension * dimension;
    const std::size_t expected_length = 1 + matrix_elements + dimension;
    if (input_length != expected_length) return -1;

    double matrix[max_dimension * max_dimension]{};
    double rhs[max_dimension]{};
    for (std::size_t index = 0; index < matrix_elements; ++index) {
        std::int64_t integer;
        if (!exact_integer_in_range(input[index + 1], -1, 1, integer)) return -1;
        matrix[index] = static_cast<double>(integer);
    }
    for (std::size_t index = 0; index < dimension; ++index) {
        std::int64_t integer;
        if (!exact_integer_in_range(input[1 + matrix_elements + index], -8, 8, integer)) return -1;
        rhs[index] = static_cast<double>(integer);
    }

    double lower[max_dimension * max_dimension]{};
    double upper[max_dimension * max_dimension]{};
    for (std::size_t row = 0; row < dimension; ++row) {
        for (std::size_t col = row; col < dimension; ++col) {
            double sum = 0.0;
            for (std::size_t index = 0; index < row; ++index) {
                const double product = rounded_multiply(lower[row * dimension + index],
                                                        upper[index * dimension + col]);
                sum = rounded_add(sum, product);
            }
            upper[row * dimension + col] = rounded_subtract(matrix[row * dimension + col], sum);
            if (!std::isfinite(upper[row * dimension + col])) return -1;
        }

        const double pivot = upper[row * dimension + row];
        if (!std::isfinite(pivot) || pivot == 0.0) return -1;
        for (std::size_t col = row; col < dimension; ++col) {
            if (row == col) {
                lower[row * dimension + col] = 1.0;
                continue;
            }
            double sum = 0.0;
            for (std::size_t index = 0; index < row; ++index) {
                const double product = rounded_multiply(lower[col * dimension + index],
                                                        upper[index * dimension + row]);
                sum = rounded_add(sum, product);
            }
            const double numerator = rounded_subtract(matrix[col * dimension + row], sum);
            const double value = rounded_divide(numerator, pivot);
            if (!std::isfinite(value)) return -1;
            lower[col * dimension + row] = value;
        }
    }

    double upper_transform[max_dimension]{};
    for (std::size_t row = 0; row < dimension; ++row) {
        double sum = 0.0;
        for (std::size_t col = 0; col < row; ++col) {
            const double product = rounded_multiply(upper_transform[col], lower[row * dimension + col]);
            sum = rounded_add(sum, product);
        }
        const double numerator = rounded_subtract(rhs[row], sum);
        upper_transform[row] = rounded_divide(numerator, lower[row * dimension + row]);
        if (!std::isfinite(upper_transform[row])) return -1;
    }

    double solution[max_dimension]{};
    for (std::size_t remaining = dimension; remaining > 0; --remaining) {
        const std::size_t row = remaining - 1;
        double sum = 0.0;
        for (std::size_t col = row; col < dimension; ++col) {
            const double product = rounded_multiply(solution[col], upper[row * dimension + col]);
            sum = rounded_add(sum, product);
        }
        const double pivot = upper[row * dimension + row];
        if (!std::isfinite(pivot) || pivot == 0.0) return -1;
        const double numerator = rounded_subtract(upper_transform[row], sum);
        solution[row] = rounded_divide(numerator, pivot);
        if (!std::isfinite(solution[row])) return -1;
    }

    if (output == nullptr || output_capacity < dimension) return -2;
    for (std::size_t index = 0; index < dimension; ++index) output[index] = solution[index];
    return static_cast<std::int64_t>(dimension);
}
