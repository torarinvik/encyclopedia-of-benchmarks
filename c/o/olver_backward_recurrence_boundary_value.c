/* Bounded Olver cutoff and backward recurrence over binary64 coefficients. */
#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_PARSEABLE_INPUT_LENGTH 53
#define MAX_NMAX 12

static int exact_integer(double value, int low, int high, int *decoded)
{
    if (!isfinite(value) || value < (double)low || value > (double)high || trunc(value) != value) return 0;
    *decoded = (int)value;
    return 1;
}

static int validate(const double *input, size_t length, int *m, int *nmax)
{
    if (input == NULL || length < 8 || length > MAX_PARSEABLE_INPUT_LENGTH) return 0;
    for (size_t i = 0; i < length; ++i) if (!isfinite(input[i])) return 0;
    if (!exact_integer(input[0], 1, 8, m) || !exact_integer(input[1], 1, MAX_NMAX, nmax)) return 0;
    if (*m > *nmax || length != 4u + 4u * (size_t)*nmax) return 0;
    if (input[2] < 0x1p-40 || input[2] > 0.5 || fabs(input[3]) > 16.0) return 0;
    for (int i = 0; i < *nmax; ++i) {
        const double a = input[4 + i];
        if (fabs(a) < 0.0625 || fabs(a) > 16.0) return 0;
        if (fabs(input[4 + *nmax + i]) > 16.0 ||
            fabs(input[4 + 2 * *nmax + i]) > 16.0 ||
            fabs(input[4 + 3 * *nmax + i]) > 16.0) return 0;
    }
    return 1;
}

int64_t olver_backward_recurrence_boundary_value(const double *input, size_t input_length,
                                                 double *output, size_t output_capacity)
{
    int m, nmax;
    if (!validate(input, input_length, &m, &nmax)) return -1;
    const size_t required = (size_t)m + 2;
    if (output == NULL || output_capacity < required) return -2;

    double p[14] = {0.0};
    double e[13] = {0.0};
    double w[13] = {0.0};
    p[1] = 1.0;
    e[0] = input[3];
    for (int n = 1; n <= m; ++n) {
        const double a = input[4 + n - 1];
        const double b = input[4 + nmax + n - 1];
        const double c = input[4 + 2 * nmax + n - 1];
        const double d = input[4 + 3 * nmax + n - 1];
        p[n + 1] = (b * p[n] - c * p[n - 1]) / a;
        e[n] = (c * e[n - 1] - d * p[n]) / a;
        if (!isfinite(p[n + 1]) || !isfinite(e[n])) return -3;
    }
    for (int n = 1; n <= m; ++n) {
        const double product = p[n] * p[n + 1];
        if (product == 0.0 || !isfinite(product) || !isfinite(e[n] / product)) return -3;
    }
    double minimum = fabs(e[1] / (p[1] * p[2]));
    for (int n = 2; n <= m; ++n) {
        const double ratio = fabs(e[n] / (p[n] * p[n + 1]));
        if (ratio < minimum) minimum = ratio;
    }
    const double threshold = input[2] * minimum;
    int endpoint = 0;
    for (int n = m; n <= nmax; ++n) {
        if (n > m) {
            const double a = input[4 + n - 1];
            const double b = input[4 + nmax + n - 1];
            const double c = input[4 + 2 * nmax + n - 1];
            const double d = input[4 + 3 * nmax + n - 1];
            p[n + 1] = (b * p[n] - c * p[n - 1]) / a;
            e[n] = (c * e[n - 1] - d * p[n]) / a;
            if (!isfinite(p[n + 1]) || !isfinite(e[n])) return -3;
        }
        const double product = p[n] * p[n + 1];
        if (product == 0.0 || !isfinite(product)) return -3;
        const double ratio = fabs(e[n] / product);
        if (!isfinite(ratio)) return -3;
        if (ratio <= threshold) { endpoint = n; break; }
    }
    if (endpoint == 0) return -3;
    w[endpoint] = 0.0;
    for (int n = endpoint - 1; n >= 0; --n) {
        w[n] = (p[n] * w[n + 1] + e[n]) / p[n + 1];
        if (!isfinite(w[n])) return -3;
    }
    output[0] = (double)endpoint;
    for (int i = 0; i <= m; ++i) output[i + 1] = w[i];
    return (int64_t)required;
}
