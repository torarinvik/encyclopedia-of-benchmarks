/* Local Gaussian weighted regression over a caller-supplied design matrix. */
#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_N 16
#define MAX_D 4
#define MAX_PARSEABLE_INPUT_LENGTH 84
#define PIVOT_FLOOR 0x1p-18

static int exact_integer(double value, int minimum, int maximum, int *result)
{
    if (!isfinite(value) || value < (double)minimum || value > (double)maximum) return 0;
    const int integer = (int)value;
    if ((double)integer != value) return 0;
    *result = integer;
    return 1;
}

static int grid_value(double value, double minimum, double maximum)
{
    if (!isfinite(value) || value < minimum || value > maximum) return 0;
    const double scaled = value * 16.0;
    return isfinite(scaled) && trunc(scaled) == scaled;
}

static int finite_value(double value)
{
    return isfinite(value);
}

static int solve_partial_pivot(double matrix[MAX_D][MAX_D], double rhs[MAX_D],
                               int dimension, double solution[MAX_D])
{
    double scale = 0.0;
    for (int index = 0; index < dimension; ++index) {
        const double diagonal = fabs(matrix[index][index]);
        if (!finite_value(diagonal)) return 0;
        if (diagonal > scale) scale = diagonal;
    }
    if (scale == 0.0 || !finite_value(scale)) return 0;

    for (int pivot_column = 0; pivot_column < dimension; ++pivot_column) {
        int pivot_row = pivot_column;
        double pivot_magnitude = fabs(matrix[pivot_row][pivot_column]);
        for (int candidate = pivot_column + 1; candidate < dimension; ++candidate) {
            const double candidate_magnitude = fabs(matrix[candidate][pivot_column]);
            if (!finite_value(candidate_magnitude)) return 0;
            if (candidate_magnitude > pivot_magnitude) {
                pivot_row = candidate;
                pivot_magnitude = candidate_magnitude;
            }
        }
        if (!finite_value(pivot_magnitude) || pivot_magnitude <= PIVOT_FLOOR * scale) return 0;

        if (pivot_row != pivot_column) {
            for (int column = 0; column < dimension; ++column) {
                const double temporary = matrix[pivot_column][column];
                matrix[pivot_column][column] = matrix[pivot_row][column];
                matrix[pivot_row][column] = temporary;
            }
            const double temporary = rhs[pivot_column];
            rhs[pivot_column] = rhs[pivot_row];
            rhs[pivot_row] = temporary;
        }

        const double pivot = matrix[pivot_column][pivot_column];
        for (int row = pivot_column + 1; row < dimension; ++row) {
            const double factor = matrix[row][pivot_column] / pivot;
            if (!finite_value(factor)) return 0;
            matrix[row][pivot_column] = 0.0;
            for (int column = pivot_column + 1; column < dimension; ++column) {
                const double product = factor * matrix[pivot_column][column];
                matrix[row][column] = matrix[row][column] - product;
                if (!finite_value(matrix[row][column])) return 0;
            }
            const double product = factor * rhs[pivot_column];
            rhs[row] = rhs[row] - product;
            if (!finite_value(rhs[row])) return 0;
        }
    }

    for (int row = dimension - 1; row >= 0; --row) {
        double residual = rhs[row];
        for (int column = row + 1; column < dimension; ++column) {
            const double product = matrix[row][column] * solution[column];
            residual = residual - product;
        }
        const double diagonal = matrix[row][row];
        if (!finite_value(residual) || diagonal == 0.0 || !finite_value(diagonal)) return 0;
        solution[row] = residual / diagonal;
        if (!finite_value(solution[row])) return 0;
    }
    return 1;
}

int64_t local_weighted_learning(const double *input, size_t input_length,
                                double *output, size_t output_capacity)
{
    if (input == NULL || input_length < 3 || input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    int n, d;
    if (!exact_integer(input[0], 2, MAX_N, &n) || !exact_integer(input[1], 1, MAX_D, &d)) return -1;
    if (d > n) return -1;
    const double tau = input[2];
    if (!grid_value(tau, 2.0, 8.0)) return -1;
    const size_t expected_length = 3u + (size_t)n * (size_t)d + (size_t)n;
    if (input_length != expected_length) return -1;

    double x_train[MAX_N][MAX_D] = {{0.0}};
    double y_train[MAX_N] = {0.0};
    size_t cursor = 3;
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

    double staged[MAX_N] = {0.0};
    for (int query = 0; query < n; ++query) {
        double weights[MAX_N] = {0.0};
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
            weights[row] = exp(exponent);
            if (!finite_value(weights[row]) || weights[row] <= 0.0) return -1;
        }

        double normal[MAX_D][MAX_D] = {{0.0}};
        double rhs[MAX_D] = {0.0};
        for (int row = 0; row < n; ++row) {
            double weighted_x[MAX_D] = {0.0};
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

        double coefficients[MAX_D] = {0.0};
        if (!solve_partial_pivot(normal, rhs, d, coefficients)) return -1;
        double prediction = 0.0;
        for (int feature = 0; feature < d; ++feature) {
            const double product = x_train[query][feature] * coefficients[feature];
            prediction = prediction + product;
        }
        if (!finite_value(prediction)) return -1;
        staged[query] = prediction;
    }

    if (output == NULL || output_capacity < (size_t)n) return -2;
    for (int index = 0; index < n; ++index) output[index] = staged[index];
    return (int64_t)n;
}
