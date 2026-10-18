#include <cmath>
#include <cstddef>
#include <cstdint>
#include <limits>

namespace {
double rounded_add(double left, double right) noexcept {
    volatile double result = left + right;
    return result;
}

double rounded_subtract(double left, double right) noexcept {
    volatile double result = left - right;
    return result;
}

double rounded_multiply(double left, double right) noexcept {
    volatile double result = left * right;
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

std::int64_t exact_determinant(const std::int64_t* source, std::size_t dimension) noexcept {
    constexpr std::size_t max_dimension = 4;
    std::int64_t matrix[max_dimension * max_dimension]{};
    const std::size_t matrix_elements = dimension * dimension;
    for (std::size_t index = 0; index < matrix_elements; ++index) matrix[index] = source[index];

    std::int64_t sign = 1;
    std::int64_t previous_pivot = 1;
    for (std::size_t col = 0; col + 1 < dimension; ++col) {
        std::size_t pivot_row = col;
        while (pivot_row < dimension && matrix[pivot_row * dimension + col] == 0) ++pivot_row;
        if (pivot_row == dimension) return 0;

        if (pivot_row != col) {
            for (std::size_t index = 0; index < dimension; ++index) {
                const auto temporary = matrix[col * dimension + index];
                matrix[col * dimension + index] = matrix[pivot_row * dimension + index];
                matrix[pivot_row * dimension + index] = temporary;
            }
            sign = -sign;
        }

        const std::int64_t pivot = matrix[col * dimension + col];
        for (std::size_t row = col + 1; row < dimension; ++row) {
            for (std::size_t trailing_col = col + 1; trailing_col < dimension; ++trailing_col) {
                std::int64_t numerator = matrix[row * dimension + trailing_col] * pivot -
                                         matrix[row * dimension + col] * matrix[col * dimension + trailing_col];
                if (col > 0) numerator /= previous_pivot;
                matrix[row * dimension + trailing_col] = numerator;
            }
            matrix[row * dimension + col] = 0;
        }
        previous_pivot = pivot;
    }

    return sign * matrix[(dimension - 1) * dimension + dimension - 1];
}

double dot_product(const double* left, const double* right, std::size_t length) noexcept {
    double total = 0.0;
    for (std::size_t index = 0; index < length; ++index) {
        const double product = rounded_multiply(left[index], right[index]);
        total = rounded_add(total, product);
    }
    return total;
}
}

extern "C" std::int64_t qr_decompose(const double* input, std::size_t input_length,
                                      double* output, std::size_t output_capacity) noexcept {
    constexpr std::size_t max_dimension = 4;
    constexpr std::size_t max_parseable_input_length = 18;
    constexpr std::size_t max_output_elements = 32;
    if (input == nullptr || input_length < 1 || input_length > max_parseable_input_length) return -1;

    std::int64_t dimension_value;
    if (!exact_integer_in_range(input[0], 1, static_cast<std::int64_t>(max_dimension), dimension_value))
        return -1;
    const auto dimension = static_cast<std::size_t>(dimension_value);
    const std::size_t matrix_elements = dimension * dimension;
    if (input_length != 1 + matrix_elements) return -1;

    std::int64_t integer_matrix[max_dimension * max_dimension]{};
    double matrix[max_dimension * max_dimension]{};
    for (std::size_t index = 0; index < matrix_elements; ++index) {
        std::int64_t integer;
        if (!exact_integer_in_range(input[index + 1], -4, 4, integer)) return -1;
        integer_matrix[index] = integer;
        matrix[index] = static_cast<double>(integer);
    }
    if (exact_determinant(integer_matrix, dimension) == 0) return -1;

    double q[max_dimension * max_dimension]{};
    double r[max_dimension * max_dimension]{};
    double source_column[max_dimension]{};
    double residual[max_dimension]{};
    double basis[max_dimension]{};
    double q_column[max_dimension]{};
    double a_column[max_dimension]{};

    for (std::size_t col = 0; col < dimension; ++col) {
        for (std::size_t row = 0; row < dimension; ++row) {
            source_column[row] = matrix[row * dimension + col];
            residual[row] = source_column[row];
        }

        for (std::size_t previous = 0; previous < col; ++previous) {
            for (std::size_t row = 0; row < dimension; ++row)
                basis[row] = q[row * dimension + previous];

            const double numerator = dot_product(source_column, basis, dimension);
            const double denominator = dot_product(basis, basis, dimension);
            if (!std::isfinite(numerator) || !std::isfinite(denominator) ||
                denominator <= std::numeric_limits<double>::epsilon()) return -1;
            const double scalar = rounded_divide(numerator, denominator);
            if (!std::isfinite(scalar)) return -1;
            for (std::size_t row = 0; row < dimension; ++row) {
                const double projection = rounded_multiply(scalar, basis[row]);
                residual[row] = rounded_subtract(residual[row], projection);
                if (!std::isfinite(residual[row])) return -1;
            }
        }

        const double residual_squared = dot_product(residual, residual, dimension);
        const double magnitude = std::sqrt(residual_squared);
        if (!std::isfinite(residual_squared) || !std::isfinite(magnitude) || magnitude == 0.0) return -1;
        for (std::size_t row = 0; row < dimension; ++row) {
            q[row * dimension + col] = rounded_divide(residual[row], magnitude);
            if (!std::isfinite(q[row * dimension + col])) return -1;
        }

        for (std::size_t row = 0; row < dimension; ++row)
            q_column[row] = q[row * dimension + col];
        for (std::size_t source_col = col; source_col < dimension; ++source_col) {
            for (std::size_t row = 0; row < dimension; ++row)
                a_column[row] = matrix[row * dimension + source_col];
            r[col * dimension + source_col] = dot_product(q_column, a_column, dimension);
            if (!std::isfinite(r[col * dimension + source_col])) return -1;
        }
    }

    double staged[max_output_elements]{};
    for (std::size_t index = 0; index < matrix_elements; ++index) {
        staged[index] = q[index];
        staged[matrix_elements + index] = r[index];
    }

    const std::size_t output_length = 2 * matrix_elements;
    if (output == nullptr || output_capacity < output_length) return -2;
    for (std::size_t index = 0; index < output_length; ++index) output[index] = staged[index];
    return static_cast<std::int64_t>(output_length);
}
