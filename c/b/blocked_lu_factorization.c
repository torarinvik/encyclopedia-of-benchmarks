#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_N 8
#define MAX_INPUT_LENGTH 66
#define MAX_OUTPUT_ELEMENTS 128

static double rounded_mul(double a, double b) { volatile double x = a * b; return x; }
static double rounded_add(double a, double b) { volatile double x = a + b; return x; }
static double rounded_sub(double a, double b) { volatile double x = a - b; return x; }
static double rounded_div(double a, double b) { volatile double x = a / b; return x; }

static int exact_integer(double value, int64_t lo, int64_t hi, int64_t *out) {
    if (!isfinite(value) || value < (double)lo || value > (double)hi) return 0;
    int64_t v = (int64_t)value;
    if ((double)v != value) return 0;
    *out = v;
    return 1;
}

int64_t blocked_lu_factorization(const double *input, size_t input_length,
                                double *output, size_t output_capacity) {
    if (input == NULL || input_length < 1 || input_length > MAX_INPUT_LENGTH) return -1;
    int64_t n64;
    if (!exact_integer(input[0], 2, MAX_N, &n64)) return -1;
    const size_t n = (size_t)n64;
    if ((n & 1U) != 0 || input_length != 1 + n * n) return -1;

    double schur[MAX_N * MAX_N] = {0.0};
    for (size_t row = 0; row < n; ++row) {
        int64_t off_sum = 0;
        for (size_t col = 0; col < n; ++col) {
            const size_t p = row * n + col;
            int64_t value;
            const int64_t lo = row == col ? 1 : -2;
            const int64_t hi = row == col ? 16 : 2;
            if (!exact_integer(input[p + 1], lo, hi, &value)) return -1;
            schur[p] = (double)value;
            if (row != col) off_sum += value < 0 ? -value : value;
        }
        if (schur[row * n + row] <= (double)off_sum) return -1;
    }

    double lower[MAX_N * MAX_N] = {0.0};
    double upper[MAX_N * MAX_N] = {0.0};
    for (size_t k = 0; k < n; k += 2) {
        const double u00 = schur[k * n + k];
        const double u01 = schur[k * n + k + 1];
        if (!isfinite(u00) || u00 == 0.0) return -1;
        const double l10 = rounded_div(schur[(k + 1) * n + k], u00);
        const double u11 = rounded_sub(schur[(k + 1) * n + k + 1], rounded_mul(l10, u01));
        if (!isfinite(l10) || !isfinite(u11) || u11 == 0.0) return -1;
        lower[k * n + k] = 1.0;
        lower[(k + 1) * n + k] = l10;
        lower[(k + 1) * n + k + 1] = 1.0;
        upper[k * n + k] = u00;
        upper[k * n + k + 1] = u01;
        upper[(k + 1) * n + k + 1] = u11;

        for (size_t j = k + 2; j < n; j += 2) {
            for (size_t col = j; col < j + 2; ++col) {
                const double s0 = schur[k * n + col];
                const double s1 = schur[(k + 1) * n + col];
                upper[k * n + col] = s0;
                upper[(k + 1) * n + col] = rounded_sub(s1, rounded_mul(l10, s0));
            }
        }
        for (size_t i = k + 2; i < n; i += 2) {
            for (size_t row = i; row < i + 2; ++row) {
                const double s0 = schur[row * n + k];
                const double s1 = schur[row * n + k + 1];
                const double l0 = rounded_div(s0, u00);
                const double l1 = rounded_div(rounded_sub(s1, rounded_mul(l0, u01)), u11);
                lower[row * n + k] = l0;
                lower[row * n + k + 1] = l1;
            }
        }
        for (size_t i = k + 2; i < n; i += 2) {
            for (size_t j = k + 2; j < n; j += 2) {
                for (size_t row = i; row < i + 2; ++row) {
                    for (size_t col = j; col < j + 2; ++col) {
                        double update = rounded_mul(lower[row * n + k], upper[k * n + col]);
                        update = rounded_add(update, rounded_mul(lower[row * n + k + 1], upper[(k + 1) * n + col]));
                        schur[row * n + col] = rounded_sub(schur[row * n + col], update);
                    }
                }
            }
        }
    }

    double staged[MAX_OUTPUT_ELEMENTS] = {0.0};
    const size_t matrix_elements = n * n;
    for (size_t row = 0; row < n; ++row) {
        for (size_t col = 0; col < n; ++col) {
            if (row == col) lower[row * n + col] = 1.0;
            if (row < col) upper[row * n + col] = schur[row * n + col];
            if (row == col) upper[row * n + col] = schur[row * n + col];
        }
    }
    for (size_t i = 0; i < matrix_elements; ++i) {
        if (!isfinite(lower[i]) || !isfinite(upper[i])) return -1;
        staged[i] = lower[i];
        staged[matrix_elements + i] = upper[i];
    }
    const size_t output_length = 2 * matrix_elements;
    if (output == NULL || output_capacity < output_length) return -2;
    for (size_t i = 0; i < output_length; ++i) output[i] = staged[i];
    return (int64_t)output_length;
}
