#include <array>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <cstring>

namespace {
constexpr std::size_t max_input_values = 11;
constexpr std::size_t max_output_bytes = 72;
constexpr std::int64_t invalid_result = -1;
constexpr std::int64_t output_error = -2;
constexpr std::int64_t coefficient_limit = 32;

double rounded_multiply(double left, double right) noexcept
{
    volatile double result = left * right;
    return result;
}

double rounded_subtract(double left, double right) noexcept
{
    volatile double result = left - right;
    return result;
}

double rounded_divide(double left, double right) noexcept
{
    volatile double result = left / right;
    return result;
}

std::int64_t absolute_coefficient(std::int64_t value) noexcept
{
    return value < 0 ? -value : value;
}

bool valid_dominance(const std::int64_t *matrix, std::size_t dimension) noexcept
{
    std::array<int, 3> dominant_column{-1, -1, -1};
    std::array<bool, 3> column_seen{false, false, false};
    for (std::size_t row = 0; row < dimension; ++row) {
        for (std::size_t column = 0; column < dimension; ++column) {
            std::int64_t other_sum = 0;
            for (std::size_t other = 0; other < dimension; ++other) {
                if (other != column)
                    other_sum += absolute_coefficient(matrix[row * dimension + other]);
            }
            if (absolute_coefficient(matrix[row * dimension + column]) > other_sum) {
                if (dominant_column[row] != -1) return false;
                dominant_column[row] = static_cast<int>(column);
            }
        }
        if (dominant_column[row] == -1 || column_seen[dominant_column[row]]) return false;
        column_seen[dominant_column[row]] = true;
    }
    return true;
}

bool scaled_pivot_inverse(const double *matrix, std::size_t dimension,
                          std::array<double, 9> &inverse) noexcept
{
    std::array<double, 9> a{};
    std::array<double, 9> b{};
    std::array<double, 3> scale{};
    std::array<int, 3> index{0, 1, 2};
    for (std::size_t row = 0; row < dimension; ++row) {
        for (std::size_t column = 0; column < dimension; ++column) {
            a[row * dimension + column] = matrix[row * dimension + column];
            if (row == column) b[row * dimension + column] = 1.0;
            const double magnitude = std::fabs(a[row * dimension + column]);
            if (magnitude > scale[row]) scale[row] = magnitude;
        }
        if (scale[row] == 0.0) return false;
    }

    for (std::size_t column = 0; column + 1 < dimension; ++column) {
        double best_ratio = 0.0;
        std::size_t best = column;
        for (std::size_t row = column; row < dimension; ++row) {
            const double ratio = rounded_divide(
                std::fabs(a[static_cast<std::size_t>(index[row]) * dimension + column]),
                scale[static_cast<std::size_t>(index[row])]);
            if (ratio > best_ratio) {
                best_ratio = ratio;
                best = row;
            }
        }

        const int temporary = index[column];
        index[column] = index[best];
        index[best] = temporary;
        const std::size_t pivot_row = static_cast<std::size_t>(index[column]);
        const double pivot = a[pivot_row * dimension + column];
        if (pivot == 0.0) return false;

        for (std::size_t row = column + 1; row < dimension; ++row) {
            const std::size_t current_row = static_cast<std::size_t>(index[row]);
            const double factor = rounded_divide(
                a[current_row * dimension + column], pivot);
            a[current_row * dimension + column] = factor;
            for (std::size_t trailing = column + 1; trailing < dimension; ++trailing) {
                const double product = rounded_multiply(
                    factor, a[pivot_row * dimension + trailing]);
                a[current_row * dimension + trailing] = rounded_subtract(
                    a[current_row * dimension + trailing], product);
            }
        }
    }

    for (std::size_t row = 0; row + 1 < dimension; ++row) {
        const std::size_t current_row = static_cast<std::size_t>(index[row]);
        for (std::size_t lower = row + 1; lower < dimension; ++lower) {
            const std::size_t lower_row = static_cast<std::size_t>(index[lower]);
            for (std::size_t column = 0; column < dimension; ++column) {
                const double product = rounded_multiply(
                    a[lower_row * dimension + row],
                    b[current_row * dimension + column]);
                b[lower_row * dimension + column] = rounded_subtract(
                    b[lower_row * dimension + column], product);
            }
        }
    }

    for (std::size_t column = 0; column < dimension; ++column) {
        const std::size_t last_row = static_cast<std::size_t>(index[dimension - 1]);
        const double last_pivot = a[last_row * dimension + dimension - 1];
        if (last_pivot == 0.0) return false;
        inverse[(dimension - 1) * dimension + column] = rounded_divide(
            b[last_row * dimension + column], last_pivot);

        for (std::size_t step = dimension - 1; step-- > 0;) {
            const std::size_t current_row = static_cast<std::size_t>(index[step]);
            double value = b[current_row * dimension + column];
            for (std::size_t trailing = step + 1; trailing < dimension; ++trailing) {
                const double product = rounded_multiply(
                    a[current_row * dimension + trailing],
                    inverse[trailing * dimension + column]);
                value = rounded_subtract(value, product);
            }
            const double pivot = a[current_row * dimension + step];
            if (pivot == 0.0) return false;
            inverse[step * dimension + column] = rounded_divide(value, pivot);
        }
    }

    for (std::size_t index = 0; index < dimension * dimension; ++index) {
        const double value = inverse[index];
        if (!std::isfinite(value)) return false;
    }
    return true;
}

void store_little_endian_double(std::uint8_t *output, double value) noexcept
{
    std::uint64_t bits;
    std::memcpy(&bits, &value, sizeof(bits));
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t inverse_of_matrix(const std::int64_t *input,
                                            std::size_t input_length,
                                            std::uint8_t *output,
                                            std::size_t output_capacity) noexcept
{
    if (input == nullptr || input_length < 1 || input_length > max_input_values)
        return invalid_result;
    if (input[0] != 2 && input[0] != 3) return invalid_result;
    const std::size_t dimension = static_cast<std::size_t>(input[0]);
    if (input_length != 1 + dimension * dimension) return invalid_result;

    std::array<std::int64_t, 9> matrix_q{};
    std::array<double, 9> matrix{};
    for (std::size_t index = 0; index < dimension * dimension; ++index) {
        const std::int64_t value = input[index + 1];
        if (value < -coefficient_limit || value > coefficient_limit)
            return invalid_result;
        matrix_q[index] = value;
        matrix[index] = static_cast<double>(value) / 16.0;
    }
    if (!valid_dominance(matrix_q.data(), dimension)) return invalid_result;

    std::array<double, 9> inverse{};
    if (!scaled_pivot_inverse(matrix.data(), dimension, inverse)) return invalid_result;

    const std::size_t output_bytes = dimension * dimension * 8;
    std::array<std::uint8_t, max_output_bytes> encoded{};
    for (std::size_t index = 0; index < dimension * dimension; ++index)
        store_little_endian_double(encoded.data() + index * 8, inverse[index]);

    if (output == nullptr || output_capacity < output_bytes) return output_error;
    std::memcpy(output, encoded.data(), output_bytes);
    return static_cast<std::int64_t>(output_bytes);
}
