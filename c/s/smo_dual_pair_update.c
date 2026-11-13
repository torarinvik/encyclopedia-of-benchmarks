#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_N 8
#define MAX_D 3
#define MAX_INPUT 47

static int field(double value, int low, int high, int *out) {
    if (!isfinite(value) || value < low || value > high || trunc(value) != value) return 0;
    *out = (int)value;
    return 1;
}

static double dot(const double a[MAX_D], const double b[MAX_D], int d) {
    double result = 0.0;
    for (int k = 0; k < d; ++k) result += a[k] * b[k];
    return result;
}

static double objective(const double a[MAX_N], const int y[MAX_N],
                        const double x[MAX_N][MAX_D], int n, int d) {
    double result = 0.0;
    for (int p = 0; p < n; ++p) result += a[p];
    for (int p = 0; p < n; ++p)
        for (int q = 0; q < n; ++q)
            result -= 0.5 * a[p] * a[q] * y[p] * y[q] * dot(x[p], x[q], d);
    return result;
}

int64_t smo_dual_pair_update(const double *input, size_t input_length,
                             double *output, size_t output_capacity) {
    if (input == NULL || input_length < 6 || input_length > MAX_INPUT) return -1;
    int n, d, c_milli, b_milli;
    if (!field(input[0], 2, MAX_N, &n) || !field(input[1], 1, MAX_D, &d) ||
        !field(input[2], 1, 5000, &c_milli) ||
        !field(input[3], -1000000, 1000000, &b_milli) ||
        input_length != (size_t)(6 + 2 * n + n * d)) return -1;

    int y[MAX_N] = {0};
    double alpha[MAX_N] = {0.0};
    double x[MAX_N][MAX_D] = {{0.0}};
    int has_negative = 0, has_positive = 0, equality = 0;
    size_t at = 4;
    for (int k = 0; k < n; ++k) {
        if (!field(input[at++], -1, 1, &y[k]) || y[k] == 0) return -1;
        has_negative |= y[k] < 0;
        has_positive |= y[k] > 0;
    }
    for (int k = 0; k < n; ++k) {
        int value;
        if (!field(input[at++], 0, c_milli, &value)) return -1;
        alpha[k] = (double)value / 1000.0;
        equality += y[k] * value;
    }
    if (!has_negative || !has_positive || equality != 0) return -1;
    for (int k = 0; k < n; ++k)
        for (int r = 0; r < d; ++r) {
            int value;
            if (!field(input[at++], -32, 32, &value)) return -1;
            x[k][r] = value;
        }
    int i, j;
    if (!field(input[at++], 0, n - 1, &i) || !field(input[at], 0, n - 1, &j) || i == j)
        return -1;
    if (output == NULL || output_capacity < (size_t)(n + 1)) return -2;

    const double c_value = (double)c_milli / 1000.0;
    const double bias = (double)b_milli / 1000.0;
    const int yi = y[i], yj = y[j], sign = yi * yj;
    const double old_i = alpha[i], old_j = alpha[j];
    const double kii = dot(x[i], x[i], d), kjj = dot(x[j], x[j], d);
    const double kij = dot(x[i], x[j], d);
    double error_i = bias - yi, error_j = bias - yj;
    for (int k = 0; k < n; ++k) {
        error_i += alpha[k] * y[k] * dot(x[k], x[i], d);
        error_j += alpha[k] * y[k] * dot(x[k], x[j], d);
    }
    double low, high;
    if (yi != yj) {
        low = fmax(0.0, old_j - old_i);
        high = fmin(c_value, c_value + old_j - old_i);
    } else {
        low = fmax(0.0, old_i + old_j - c_value);
        high = fmin(c_value, old_i + old_j);
    }

    const double eta = 2.0 * kij - kii - kjj;
    double new_j;
    if (eta < 0.0) {
        new_j = old_j - yj * (error_i - error_j) / eta;
        new_j = fmin(high, fmax(low, new_j));
    } else {
        double candidate[MAX_N];
        for (int k = 0; k < n; ++k) candidate[k] = alpha[k];
        candidate[i] = old_i + sign * (old_j - low);
        candidate[j] = low;
        double low_score = objective(candidate, y, x, n, d);
        candidate[i] = old_i + sign * (old_j - high);
        candidate[j] = high;
        double high_score = objective(candidate, y, x, n, d);
        new_j = high_score > low_score ? high : low;
    }
    const double new_i = old_i + sign * (old_j - new_j);
    const double delta_i = new_i - old_i, delta_j = new_j - old_j;
    const double bias_i = bias - error_i - yi * delta_i * kii - yj * delta_j * kij;
    const double bias_j = bias - error_j - yi * delta_i * kij - yj * delta_j * kjj;
    const double new_bias = (new_i > 0.0 && new_i < c_value) ? bias_i :
                            (new_j > 0.0 && new_j < c_value) ? bias_j :
                            0.5 * (bias_i + bias_j);
    alpha[i] = new_i;
    alpha[j] = new_j;
    for (int k = 0; k < n; ++k) output[k] = alpha[k];
    output[n] = new_bias;
    return n + 1;
}
