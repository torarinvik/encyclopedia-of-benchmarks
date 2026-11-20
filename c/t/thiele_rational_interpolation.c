#include <math.h>
#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 6, MAX_INPUT = 15 };
#define GRID_DENOMINATOR 18014398509481984.0
#define MIN_NODE_SEPARATION 0.0625
#define MIN_MAGNITUDE 0.03125
#define MAX_MAGNITUDE 64.0
#define BOUNDARY_GUARD 0.00000000023283064365386963

static int finite_in_range(double value)
{
    if (!isfinite(value) || value < -8.0 || value > 8.0) return 0;
    return trunc(value * GRID_DENOMINATOR) == value * GRID_DENOMINATOR;
}

int64_t thiele_rational_interpolation(const double *input, size_t input_length,
                                      double *output, size_t output_capacity)
{
    if (input == NULL || input_length < 4 || input_length > MAX_INPUT) return -1;
    const double n_value = input[0];
    if (!finite_in_range(n_value) || trunc(n_value) != n_value || n_value < 1.0 || n_value > MAX_N)
        return -1;
    const size_t n = (size_t)n_value;
    if (input_length != 2 + 2 * n) return -1;

    double x[MAX_N], y[MAX_N], difference[MAX_N * MAX_N] = {0.0};
    for (size_t i = 0; i < n; ++i) {
        x[i] = input[1 + 2 * i];
        y[i] = input[2 + 2 * i];
        if (!finite_in_range(x[i]) || !finite_in_range(y[i])) return -1;
        for (size_t j = 0; j < i; ++j)
            if (x[i] == x[j] || fabs(x[i] - x[j]) < MIN_NODE_SEPARATION) return -1;
        difference[i] = y[i];
    }
    const double query = input[input_length - 1];
    if (!finite_in_range(query)) return -1;

    for (size_t order = 1; order < n; ++order) {
        for (size_t endpoint = order; endpoint < n; ++endpoint) {
            const double denominator = difference[(order - 1) * MAX_N + order - 1]
                                     - difference[(order - 1) * MAX_N + endpoint];
            if (!isfinite(denominator) || fabs(denominator) <= MIN_MAGNITUDE + BOUNDARY_GUARD || fabs(denominator) >= MAX_MAGNITUDE - BOUNDARY_GUARD) return -1;
            const double value = (x[order - 1] - x[endpoint]) / denominator;
            if (!isfinite(value) || fabs(value) >= MAX_MAGNITUDE - BOUNDARY_GUARD) return -1;
            difference[order * MAX_N + endpoint] = value;
        }
        if (fabs(difference[order * MAX_N + order]) <= MIN_MAGNITUDE + BOUNDARY_GUARD || fabs(difference[order * MAX_N + order]) >= MAX_MAGNITUDE - BOUNDARY_GUARD) return -1;
    }

    double result;
    int at_node = 0;
    for (size_t i = 0; i < n; ++i) {
        if (query == x[i]) { result = y[i]; at_node = 1; break; }
    }
    if (!at_node && n == 1) result = y[0];
    if (!at_node && n > 1) {
        double tail = difference[(n - 1) * MAX_N + n - 1];
        for (size_t order = n - 2; order > 0; --order) {
            if (!isfinite(tail) || fabs(tail) <= MIN_MAGNITUDE + BOUNDARY_GUARD || fabs(tail) >= MAX_MAGNITUDE - BOUNDARY_GUARD) return -1;
            tail = difference[order * MAX_N + order] + (query - x[order]) / tail;
            if (!isfinite(tail) || fabs(tail) >= MAX_MAGNITUDE - BOUNDARY_GUARD) return -1;
        }
        if (!isfinite(tail) || fabs(tail) <= MIN_MAGNITUDE + BOUNDARY_GUARD || fabs(tail) >= MAX_MAGNITUDE - BOUNDARY_GUARD) return -1;
        result = y[0] + (query - x[0]) / tail;
    }
    if (!isfinite(result) || fabs(result) >= MAX_MAGNITUDE - BOUNDARY_GUARD) return -1;
    if (output == NULL || output_capacity < 1) return -2;
    output[0] = result;
    return 1;
}
