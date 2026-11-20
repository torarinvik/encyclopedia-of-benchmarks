#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_N 8
#define MAX_D 3
#define MAX_INPUT 37
#define MAX_OUTPUT 12
#define TOL 0.001
#define EPS 0.001

static int integer_field(double value, int low, int high, int *out) {
    if (!isfinite(value) || value < low || value > high || trunc(value) != value) return 0;
    *out = (int)value;
    return 1;
}

static double kernel(const double x[MAX_N][MAX_D], int a, int b, int d) {
    double sum = 0.0;
    for (int k = 0; k < d; ++k) sum += x[a][k] * x[b][k];
    return sum;
}

static double decision(int index, const double alpha[MAX_N], double bias,
                       const int y[MAX_N], const double x[MAX_N][MAX_D],
                       int n, int d) {
    double value = bias;
    for (int k = 0; k < n; ++k) value += alpha[k] * y[k] * kernel(x, k, index, d);
    return value;
}

static double dual(const double alpha[MAX_N], const int y[MAX_N],
                   const double x[MAX_N][MAX_D], int n, int d) {
    double value = 0.0;
    for (int i = 0; i < n; ++i) value += alpha[i];
    for (int i = 0; i < n; ++i)
        for (int j = 0; j < n; ++j)
            value -= 0.5 * alpha[i] * alpha[j] * y[i] * y[j] * kernel(x, i, j, d);
    return value;
}

static int take_step(int i, int j, double alpha[MAX_N], double *bias, double c,
                     const int y[MAX_N], const double x[MAX_N][MAX_D], int n, int d) {
    if (i == j) return 0;
    const int yi = y[i], yj = y[j], sign = yi * yj;
    const double old_i = alpha[i], old_j = alpha[j];
    const double e_i = decision(i, alpha, *bias, y, x, n, d) - yi;
    const double e_j = decision(j, alpha, *bias, y, x, n, d) - yj;
    double low, high;
    if (yi != yj) {
        low = fmax(0.0, old_j - old_i);
        high = fmin(c, c + old_j - old_i);
    } else {
        low = fmax(0.0, old_i + old_j - c);
        high = fmin(c, old_i + old_j);
    }
    if (low == high) return 0;
    const double kii = kernel(x, i, i, d), kjj = kernel(x, j, j, d);
    const double kij = kernel(x, i, j, d);
    const double curvature = kii + kjj - 2.0 * kij;
    double new_j;
    if (curvature > 0.0) {
        new_j = old_j + yj * (e_i - e_j) / curvature;
        new_j = fmin(high, fmax(low, new_j));
    } else {
        double trial[MAX_N];
        for (int k = 0; k < n; ++k) trial[k] = alpha[k];
        trial[i] = old_i + sign * (old_j - low);
        trial[j] = low;
        const double low_value = dual(trial, y, x, n, d);
        trial[i] = old_i + sign * (old_j - high);
        trial[j] = high;
        const double high_value = dual(trial, y, x, n, d);
        if (low_value > high_value + EPS) new_j = low;
        else if (high_value > low_value + EPS) new_j = high;
        else new_j = old_j;
    }
    if (fabs(new_j - old_j) < EPS * (new_j + old_j + EPS)) return 0;
    const double new_i = old_i + sign * (old_j - new_j);
    const double di = new_i - old_i, dj = new_j - old_j;
    const double b_i = *bias - e_i - yi * di * kii - yj * dj * kij;
    const double b_j = *bias - e_j - yi * di * kij - yj * dj * kjj;
    if (new_i > 0.0 && new_i < c) *bias = b_i;
    else if (new_j > 0.0 && new_j < c) *bias = b_j;
    else *bias = 0.5 * (b_i + b_j);
    alpha[i] = new_i;
    alpha[j] = new_j;
    return 1;
}

static int examine(int j, double alpha[MAX_N], double *bias, double c,
                   const int y[MAX_N], const double x[MAX_N][MAX_D], int n, int d) {
    const double e_j = decision(j, alpha, *bias, y, x, n, d) - y[j];
    const double r = e_j * y[j];
    if (!((r < -TOL && alpha[j] < c) || (r > TOL && alpha[j] > 0.0))) return 0;
    int free_count = 0, best = -1;
    double best_gap = -1.0;
    for (int i = 0; i < n; ++i) {
        if (alpha[i] > 0.0 && alpha[i] < c) {
            ++free_count;
            const double e_i = decision(i, alpha, *bias, y, x, n, d) - y[i];
            const double gap = fabs(e_i - e_j);
            if (gap > best_gap) { best_gap = gap; best = i; }
        }
    }
    if (free_count > 1 && take_step(best, j, alpha, bias, c, y, x, n, d)) return 1;
    for (int i = 0; i < n; ++i)
        if (alpha[i] > 0.0 && alpha[i] < c && take_step(i, j, alpha, bias, c, y, x, n, d))
            return 1;
    for (int i = 0; i < n; ++i)
        if (take_step(i, j, alpha, bias, c, y, x, n, d)) return 1;
    return 0;
}

int64_t smo_deterministic_training(const double *input, size_t input_length,
                                  double *output, size_t output_capacity) {
    if (input == NULL || input_length < 4 || input_length > MAX_INPUT) return -1;
    int n, d, c_milli, pass_cap;
    if (!integer_field(input[0], 2, MAX_N, &n) ||
        !integer_field(input[1], 1, MAX_D, &d) ||
        !integer_field(input[2], 1, 5000, &c_milli) ||
        !integer_field(input[3], 1, 16, &pass_cap) ||
        input_length != (size_t)(4 + n + n * d)) return -1;
    int y[MAX_N] = {0}, positive = 0, negative = 0;
    double x[MAX_N][MAX_D] = {{0.0}}, alpha[MAX_N] = {0.0};
    size_t at = 4;
    for (int i = 0; i < n; ++i) {
        if (!integer_field(input[at++], -1, 1, &y[i]) || y[i] == 0) return -1;
        if (y[i] > 0) positive = 1; else negative = 1;
    }
    if (!positive || !negative) return -1;
    for (int i = 0; i < n; ++i)
        for (int k = 0; k < d; ++k) {
            int value;
            if (!integer_field(input[at++], -32, 32, &value)) return -1;
            x[i][k] = value;
        }
    if (output == NULL || output_capacity < (size_t)(n + 4)) return -2;

    double bias = 0.0, c = (double)c_milli / 1000.0;
    int changed = 0, examine_all = 1, passes = 0;
    while (passes < pass_cap && (changed > 0 || examine_all)) {
        changed = 0;
        for (int j = 0; j < n; ++j)
            if ((examine_all || (alpha[j] > 0.0 && alpha[j] < c)) &&
                examine(j, alpha, &bias, c, y, x, n, d)) ++changed;
        ++passes;
        if (examine_all) examine_all = 0;
        else if (changed == 0) examine_all = 1;
    }
    double staged[MAX_OUTPUT] = {0.0};
    staged[0] = passes;
    staged[1] = changed;
    staged[2] = (passes < pass_cap && changed == 0 && !examine_all) ? 1.0 : 0.0;
    for (int i = 0; i < n; ++i) staged[3 + i] = alpha[i];
    staged[3 + n] = bias;
    for (int i = 0; i < n + 4; ++i) output[i] = staged[i];
    return n + 4;
}
