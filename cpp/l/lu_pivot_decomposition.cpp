#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
double rounded_multiply(double left, double right) noexcept {
    volatile double result = left * right;
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

extern "C" std::int64_t lu_pivot_decomposition(const double* input, std::size_t input_length,
                                                double* output, std::size_t output_capacity) noexcept {
    constexpr std::size_t max_dimension = 4;
    constexpr std::size_t max_parseable_input_length = 18;
    constexpr std::size_t max_output_elements = 21;
    if (input == nullptr || input_length < 1 || input_length > max_parseable_input_length) return -1;

    std::int64_t dimension_value;
    if (!exact_integer_in_range(input[0], 1, static_cast<std::int64_t>(max_dimension), dimension_value))
        return -1;
    const auto dimension = static_cast<std::size_t>(dimension_value);
    const std::size_t matrix_elements = dimension * dimension;
    if (input_length != 1 + matrix_elements) return -1;

    double packed_lu[max_dimension * max_dimension]{};
    for (std::size_t index = 0; index < matrix_elements; ++index) {
        std::int64_t integer;
        if (!exact_integer_in_range(input[index + 1], -8, 8, integer)) return -1;
        packed_lu[index] = static_cast<double>(integer);
    }

    std::int64_t pivot[max_dimension + 1]{};
    for (std::size_t index = 0; index <= dimension; ++index)
        pivot[index] = static_cast<std::int64_t>(index);

    for (std::size_t col = 0; col < dimension; ++col) {
        double max_value = 0.0;
        std::size_t max_index = col;
        for (std::size_t row = col; row < dimension; ++row) {
            const double entry = packed_lu[row * dimension + col];
            const double magnitude = entry < 0.0 ? -entry : entry;
            if (magnitude > max_value) {
                max_value = magnitude;
                max_index = row;
            }
        }

        if (max_index != col) {
            for (std::size_t index = 0; index < dimension; ++index) {
                const double temporary = packed_lu[col * dimension + index];
                packed_lu[col * dimension + index] = packed_lu[max_index * dimension + index];
                packed_lu[max_index * dimension + index] = temporary;
            }
            const auto temporary = pivot[col];
            pivot[col] = pivot[max_index];
            pivot[max_index] = temporary;
            pivot[dimension]++;
        }

        const double pivot_value = packed_lu[col * dimension + col];
        if (!std::isfinite(pivot_value) || pivot_value == 0.0) return -1;

        for (std::size_t row = col + 1; row < dimension; ++row) {
            const double multiplier = rounded_divide(packed_lu[row * dimension + col], pivot_value);
            if (!std::isfinite(multiplier)) return -1;
            packed_lu[row * dimension + col] = multiplier;

            for (std::size_t trailing_col = col + 1; trailing_col < dimension; ++trailing_col) {
                const double product = rounded_multiply(multiplier,
                                                        packed_lu[col * dimension + trailing_col]);
                const double value = rounded_subtract(packed_lu[row * dimension + trailing_col], product);
                if (!std::isfinite(value)) return -1;
                packed_lu[row * dimension + trailing_col] = value;
            }
        }
    }

    double staged[max_output_elements]{};
    for (std::size_t index = 0; index < matrix_elements; ++index) {
        if (!std::isfinite(packed_lu[index])) return -1;
        staged[index] = packed_lu[index];
    }
    const std::size_t output_length = matrix_elements + dimension + 1;
    for (std::size_t index = 0; index <= dimension; ++index)
        staged[matrix_elements + index] = static_cast<double>(pivot[index]);

    if (output == nullptr || output_capacity < output_length) return -2;
    for (std::size_t index = 0; index < output_length; ++index) output[index] = staged[index];
    return static_cast<std::int64_t>(output_length);
}
