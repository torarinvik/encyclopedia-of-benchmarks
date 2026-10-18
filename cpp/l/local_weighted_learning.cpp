#include <array>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <utility>

namespace {
constexpr int kMaxN = 16;
constexpr int kMaxD = 4;
constexpr std::size_t kMaxParseableInputLength = 84;
constexpr double kPivotFloor = 0x1p-18;

bool exact_integer(double value, int minimum, int maximum, int& result) noexcept
{
    if (!std::isfinite(value) || value < minimum || value > maximum) return false;
    const int integer = static_cast<int>(value);
    if (static_cast<double>(integer) != value) return false;
    result = integer;
    return true;
}

bool grid_value(double value, double minimum, double maximum) noexcept
{
    if (!std::isfinite(value) || value < minimum || value > maximum) return false;
    const double scaled = value * 16.0;
    return std::isfinite(scaled) && std::trunc(scaled) == scaled;
}

bool solve_partial_pivot(std::array<std::array<double, kMaxD>, kMaxD>& matrix,
                         std::array<double, kMaxD>& rhs, int dimension,
                         std::array<double, kMaxD>& solution) noexcept
{
    double scale = 0.0;
    for (int index = 0; index < dimension; ++index) {
        const double diagonal = std::abs(matrix[index][index]);
        if (!std::isfinite(diagonal)) return false;
        if (diagonal > scale) scale = diagonal;
    }
    if (scale == 0.0 || !std::isfinite(scale)) return false;

    for (int pivot_column = 0; pivot_column < dimension; ++pivot_column) {
        int pivot_row = pivot_column;
        double pivot_magnitude = std::abs(matrix[pivot_row][pivot_column]);
        for (int candidate = pivot_column + 1; candidate < dimension; ++candidate) {
            const double candidate_magnitude = std::abs(matrix[candidate][pivot_column]);
            if (!std::isfinite(candidate_magnitude)) return false;
            if (candidate_magnitude > pivot_magnitude) {
                pivot_row = candidate;
                pivot_magnitude = candidate_magnitude;
            }
        }
        if (!std::isfinite(pivot_magnitude) || pivot_magnitude <= kPivotFloor * scale) return false;

        if (pivot_row != pivot_column) {
            for (int column = 0; column < dimension; ++column)
                std::swap(matrix[pivot_column][column], matrix[pivot_row][column]);
            std::swap(rhs[pivot_column], rhs[pivot_row]);
        }

        const double pivot = matrix[pivot_column][pivot_column];
        for (int row = pivot_column + 1; row < dimension; ++row) {
            const double factor = matrix[row][pivot_column] / pivot;
            if (!std::isfinite(factor)) return false;
            matrix[row][pivot_column] = 0.0;
            for (int column = pivot_column + 1; column < dimension; ++column) {
                const double product = factor * matrix[pivot_column][column];
                matrix[row][column] = matrix[row][column] - product;
                if (!std::isfinite(matrix[row][column])) return false;
            }
            const double product = factor * rhs[pivot_column];
            rhs[row] = rhs[row] - product;
            if (!std::isfinite(rhs[row])) return false;
        }
    }

    for (int row = dimension - 1; row >= 0; --row) {
        double residual = rhs[row];
        for (int column = row + 1; column < dimension; ++column) {
            const double product = matrix[row][column] * solution[column];
            residual = residual - product;
        }
        const double diagonal = matrix[row][row];
        if (!std::isfinite(residual) || diagonal == 0.0 || !std::isfinite(diagonal)) return false;
        solution[row] = residual / diagonal;
        if (!std::isfinite(solution[row])) return false;
    }
    return true;
}
}

extern "C" std::int64_t local_weighted_learning(const double* input,
    std::size_t input_length, double* output, std::size_t output_capacity) noexcept
{
    if (input == nullptr || input_length < 3 || input_length > kMaxParseableInputLength) return -1;
    int n, d;
    if (!exact_integer(input[0], 2, kMaxN, n) || !exact_integer(input[1], 1, kMaxD, d)) return -1;
    if (d > n) return -1;
    const double tau = input[2];
    if (!grid_value(tau, 2.0, 8.0)) return -1;
    const std::size_t expected_length = 3 + static_cast<std::size_t>(n) * d + n;
    if (input_length != expected_length) return -1;

    std::array<std::array<double, kMaxD>, kMaxN> x_train{};
    std::array<double, kMaxN> y_train{};
    std::size_t cursor = 3;
    for (int row = 0; row < n; ++row) {
        for (int feature = 0; feature < d; ++feature) {
            const double value = input[cursor++];
            if (!grid_value(value, -4.0, 4.0)) return -1;
            x_train[row][feature] = value;
        }
    }
    for (int row = 0; row < n; ++row) {
        const double value = input[cursor++];
        if (!grid_value(value, -8.0, 8.0)) return -1;
        y_train[row] = value;
    }

    std::array<double, kMaxN> staged{};
    for (int query = 0; query < n; ++query) {
        std::array<double, kMaxN> weights{};
        for (int row = 0; row < n; ++row) {
            double distance_squared = 0.0;
            for (int feature = 0; feature < d; ++feature) {
                const double delta = x_train[query][feature] - x_train[row][feature];
                const double squared_delta = delta * delta;
                distance_squared = distance_squared + squared_delta;
            }
            const double tau_squared = tau * tau;
            const double denominator = (-2.0) * tau_squared;
            const double exponent = distance_squared / denominator;
            weights[row] = std::exp(exponent);
            if (!std::isfinite(weights[row]) || weights[row] <= 0.0) return -1;
        }

        std::array<std::array<double, kMaxD>, kMaxD> normal{};
        std::array<double, kMaxD> rhs{};
        for (int row = 0; row < n; ++row) {
            std::array<double, kMaxD> weighted_x{};
            for (int feature = 0; feature < d; ++feature)
                weighted_x[feature] = weights[row] * x_train[row][feature];
            const double weighted_y = weights[row] * y_train[row];
            for (int p = 0; p < d; ++p) {
                const double rhs_product = x_train[row][p] * weighted_y;
                rhs[p] = rhs[p] + rhs_product;
                for (int q = 0; q < d; ++q) {
                    const double product = x_train[row][p] * weighted_x[q];
                    normal[p][q] = normal[p][q] + product;
                }
            }
        }

        std::array<double, kMaxD> coefficients{};
        if (!solve_partial_pivot(normal, rhs, d, coefficients)) return -1;
        double prediction = 0.0;
        for (int feature = 0; feature < d; ++feature) {
            const double product = x_train[query][feature] * coefficients[feature];
            prediction = prediction + product;
        }
        if (!std::isfinite(prediction)) return -1;
        staged[query] = prediction;
    }

    if (output == nullptr || output_capacity < static_cast<std::size_t>(n)) return -2;
    for (int index = 0; index < n; ++index) output[index] = staged[index];
    return n;
}
