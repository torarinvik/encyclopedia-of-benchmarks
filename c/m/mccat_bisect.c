#include <stddef.h>
#include <stdint.h>
#include <string.h>

#define MAX_N 32
#define MAX_OUTPUT_BYTES ((MAX_N + 1) * 8)
#define EPSILON 2.2204460492503131e-16
#define INVALID_RESULT (-1)
#define OUTPUT_ERROR (-2)

static double absolute_value(double value) { return value < 0.0 ? -value : value; }

static int sturm(int n, const double *diagonal, const double *off_diagonal,
                 const double *beta, double x) {
    int negative_count = 0;
    double q = 1.0;
    for (int i = 0; i < n; ++i) {
        if (q != 0.0)
            q = (diagonal[i] - x) - beta[i] / q;
        else
            q = (diagonal[i] - x) - absolute_value(off_diagonal[i]) / EPSILON;
        if (q < 0.0) ++negative_count;
    }
    return negative_count;
}

static size_t store_f64_le(double value, uint8_t *output, size_t offset) {
    uint64_t bits;
    memcpy(&bits, &value, sizeof(bits));
    for (size_t i = 0; i < 8; ++i) output[offset + i] = (uint8_t)(bits >> (8u * i));
    return offset + 8;
}

static size_t solve(int n, uint8_t *staged) {
    double diagonal[MAX_N] = {0.0}, off_diagonal[MAX_N] = {0.0}, beta[MAX_N] = {0.0};
    double eigenvalues[MAX_N + 1] = {0.0}, lower_bounds[MAX_N + 1] = {0.0};
    for (int i = 0; i < n; ++i) {
        const double value = (double)(i + 1);
        diagonal[i] = value * value;
        diagonal[i] = diagonal[i] * diagonal[i];
        off_diagonal[i] = (double)i;
        beta[i] = off_diagonal[i] * off_diagonal[i];
    }
    beta[0] = off_diagonal[0] = 0.0;

    const double fudge = 1.01;
    double xmin = diagonal[n - 1] - fudge * absolute_value(off_diagonal[n - 1]);
    double xmax = diagonal[n - 1] + fudge * absolute_value(off_diagonal[n - 1]);
    for (int i = n - 2; i >= 0; --i) {
        const double h = fudge * (absolute_value(off_diagonal[i]) + absolute_value(off_diagonal[i + 1]));
        if (diagonal[i] + h > xmax) xmax = diagonal[i] + h;
        if (diagonal[i] - h < xmin) xmin = diagonal[i] - h;
    }
    double eps2 = EPSILON * (xmin + xmax > 0.0 ? xmax : -xmin);
    double eps1 = EPSILON;
    if (eps1 <= 0.0) eps1 = eps2;
    eps2 = 0.5 * eps1 + 7.0 * eps2;

    double x0 = xmax;
    for (int i = n; i >= 1; --i) {
        eigenvalues[i] = xmax;
        lower_bounds[i] = xmin;
    }
    int iterations = 0;
    for (int k = n; k >= 1; --k) {
        double xu = xmin;
        for (int i = k; i >= 1; --i) {
            if (xu < lower_bounds[i]) {
                xu = lower_bounds[i];
                break;
            }
        }
        if (x0 > eigenvalues[k]) x0 = eigenvalues[k];
        double x1 = (xu + x0) / 2.0;
        while (x0 - xu > 2.0 * EPSILON * (absolute_value(xu) + absolute_value(x0)) + eps1) {
            ++iterations;
            const int count = sturm(n, diagonal, off_diagonal, beta, x1);
            if (count < k) {
                if (count < 1) {
                    xu = lower_bounds[1] = x1;
                } else {
                    xu = lower_bounds[count + 1] = x1;
                    if (eigenvalues[count] > x1) eigenvalues[count] = x1;
                }
            } else {
                x0 = x1;
            }
            x1 = (xu + x0) / 2.0;
        }
        eigenvalues[k] = (xu + x0) / 2.0;
    }

    size_t used = 0;
    for (int i = 2; i <= n; ++i) used = store_f64_le(eigenvalues[i], staged, used);
    used = store_f64_le(eps2, staged, used);
    used = store_f64_le((double)iterations, staged, used);
    return used;
}

int64_t mccat_bisect(const int64_t *values, size_t length,
                     uint8_t *output, size_t output_capacity) {
    if (values == NULL || length != 1 || values[0] < 2 || values[0] > MAX_N)
        return INVALID_RESULT;
    const size_t required = ((size_t)values[0] + 1u) * 8u;
    if (output == NULL || output_capacity < required) return OUTPUT_ERROR;

    uint8_t staged[MAX_OUTPUT_BYTES];
    const size_t used = solve((int)values[0], staged);
    for (size_t i = 0; i < used; ++i) output[i] = staged[i];
    return (int64_t)used;
}
