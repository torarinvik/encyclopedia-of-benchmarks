#include <stddef.h>
#include <stdint.h>

#define MAX_N 8
#define MAX_M 16
#define MAX_CELLS (MAX_N * MAX_N)
#define MAX_A_CELLS (MAX_N * MAX_M)

static int dimension_value(double value, int maximum)
{
    if (!(value >= 1.0 && value <= (double)maximum)) return 0;
    return (double)(int)value == value;
}

int64_t syrk(const double *input, size_t length, double *output, size_t capacity)
{
    if (input == NULL || length != 2 || !dimension_value(input[0], MAX_N) ||
        !dimension_value(input[1], MAX_M)) return -1;
    const size_t n = (size_t)input[0];
    const size_t m = (size_t)input[1];
    const double alpha = 1.5;
    const double beta = 1.2;
    double a[MAX_A_CELLS];
    double c[MAX_CELLS];

    for (size_t i = 0; i < n; ++i)
        for (size_t k = 0; k < m; ++k)
            a[i * m + k] = (double)((i * k + 1) % n) / (double)n;
    for (size_t i = 0; i < n; ++i)
        for (size_t j = 0; j < n; ++j)
            c[i * n + j] = (double)((i * j + 2) % m) / (double)m;

    for (size_t i = 0; i < n; ++i) {
        for (size_t j = 0; j <= i; ++j) c[i * n + j] *= beta;
        for (size_t k = 0; k < m; ++k)
            for (size_t j = 0; j <= i; ++j)
                c[i * n + j] += alpha * a[i * m + k] * a[j * m + k];
    }

    const size_t required = n * n;
    if (output == NULL || capacity < required) return -2;
    for (size_t index = 0; index < required; ++index) output[index] = c[index];
    return (int64_t)required;
}
