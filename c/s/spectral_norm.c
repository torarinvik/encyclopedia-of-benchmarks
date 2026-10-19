#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_DIMENSION 64
#define INVALID_RESULT (-1e300)

static double matrix_entry(size_t i, size_t j) {
    const size_t triangular = (i + j) * (i + j + 1) / 2;
    return 1.0 / (double)(triangular + i + 1);
}

static void multiply_a(size_t n, const double *input, double *output) {
    for (size_t i = 0; i < n; ++i) {
        double total = 0.0;
        for (size_t j = 0; j < n; ++j) total += matrix_entry(i, j) * input[j];
        output[i] = total;
    }
}

static void multiply_at(size_t n, const double *input, double *output) {
    for (size_t i = 0; i < n; ++i) {
        double total = 0.0;
        for (size_t j = 0; j < n; ++j) total += matrix_entry(j, i) * input[j];
        output[i] = total;
    }
}

static void multiply_ata(size_t n, const double *input, double *output,
                         double *temporary) {
    multiply_a(n, input, temporary);
    multiply_at(n, temporary, output);
}

double spectral_norm(const int64_t *values, size_t length) {
    if (values == NULL || length != 1 || values[0] < 1 || values[0] > MAX_DIMENSION)
        return INVALID_RESULT;
    const size_t n = (size_t)values[0];
    double u[MAX_DIMENSION], v[MAX_DIMENSION], temporary[MAX_DIMENSION];
    for (size_t i = 0; i < n; ++i) u[i] = 1.0;
    for (size_t iteration = 0; iteration < 10; ++iteration) {
        multiply_ata(n, u, v, temporary);
        multiply_ata(n, v, u, temporary);
    }
    double v_b_v = 0.0, v_v = 0.0;
    for (size_t i = 0; i < n; ++i) {
        v_b_v += u[i] * v[i];
        v_v += v[i] * v[i];
    }
    return sqrt(v_b_v / v_v);
}
