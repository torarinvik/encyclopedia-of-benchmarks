#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define HPL_MAX_N 8
#define HPL_MAX_INPUT_LENGTH 66
#define HPL_MAX_OUTPUT_ELEMENTS 72

static int hpl_exact_integer(double value, int64_t lo, int64_t hi, int64_t *out) {
    if (!isfinite(value) || value < (double)lo || value > (double)hi) return 0;
    int64_t integer = (int64_t)value;
    if ((double)integer != value) return 0;
    *out = integer;
    return 1;
}

int64_t hpl_blocked_partial_pivot_lu(const double *input, size_t input_length,
                                    double *output, size_t output_capacity) {
    if (input == NULL || input_length < 1 || input_length > HPL_MAX_INPUT_LENGTH) return -1;
    int64_t n_value;
    if (!hpl_exact_integer(input[0], 2, HPL_MAX_N, &n_value)) return -1;
    const size_t n = (size_t)n_value;
    if (input_length != 1 + n * n) return -1;

    double a[HPL_MAX_N * HPL_MAX_N] = {0.0};
    for (size_t i = 0; i < n * n; ++i) {
        int64_t value;
        if (!hpl_exact_integer(input[i + 1], -16, 16, &value)) return -1;
        a[i] = (double)value;
    }

    size_t pivots[HPL_MAX_N] = {0};
    for (size_t panel = 0; panel < n; panel += 2) {
        const size_t panel_end = panel + 2 < n ? panel + 2 : n;
        for (size_t col = panel; col < panel_end; ++col) {
            size_t pivot_row = col;
            double pivot_magnitude = fabs(a[col * n + col]);
            for (size_t row = col + 1; row < n; ++row) {
                const double magnitude = fabs(a[row * n + col]);
                if (magnitude > pivot_magnitude) {
                    pivot_magnitude = magnitude;
                    pivot_row = row;
                }
            }
            if (!isfinite(pivot_magnitude) || pivot_magnitude == 0.0) return -1;
            pivots[col] = pivot_row;
            if (pivot_row != col) {
                for (size_t j = 0; j < n; ++j) {
                    const double temporary = a[col * n + j];
                    a[col * n + j] = a[pivot_row * n + j];
                    a[pivot_row * n + j] = temporary;
                }
            }
            const double diagonal = a[col * n + col];
            if (!isfinite(diagonal) || diagonal == 0.0) return -1;
            for (size_t row = col + 1; row < n; ++row) {
                a[row * n + col] /= diagonal;
                if (!isfinite(a[row * n + col])) return -1;
                const double multiplier = a[row * n + col];
                for (size_t j = col + 1; j < panel_end; ++j) {
                    a[row * n + j] -= multiplier * a[col * n + j];
                    if (!isfinite(a[row * n + j])) return -1;
                }
            }
        }
        for (size_t row = panel; row < panel_end; ++row) {
            for (size_t col = panel_end; col < n; ++col) {
                double value = a[row * n + col];
                for (size_t inner = panel; inner < row; ++inner)
                    value -= a[row * n + inner] * a[inner * n + col];
                if (!isfinite(value)) return -1;
                a[row * n + col] = value;
            }
        }
        for (size_t row = panel_end; row < n; ++row) {
            for (size_t col = panel_end; col < n; ++col) {
                double update = 0.0;
                for (size_t inner = panel; inner < panel_end; ++inner)
                    update += a[row * n + inner] * a[inner * n + col];
                a[row * n + col] -= update;
                if (!isfinite(a[row * n + col])) return -1;
            }
        }
    }

    double staged[HPL_MAX_OUTPUT_ELEMENTS] = {0.0};
    for (size_t i = 0; i < n; ++i) staged[i] = (double)pivots[i];
    for (size_t i = 0; i < n * n; ++i) {
        if (!isfinite(a[i])) return -1;
        staged[n + i] = a[i];
    }
    const size_t output_length = n + n * n;
    if (output == NULL || output_capacity < output_length) return -2;
    for (size_t i = 0; i < output_length; ++i) output[i] = staged[i];
    return (int64_t)output_length;
}
