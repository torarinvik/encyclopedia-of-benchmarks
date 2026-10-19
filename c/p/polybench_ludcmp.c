#include <stddef.h>
#include <stdint.h>

#define MAX_DIMENSION 64
#define MAX_CELLS (MAX_DIMENSION * MAX_DIMENSION)
#define INVALID_RESULT (-1e300)

double polybench_ludcmp(const int64_t *values, size_t length) {
    if (values == NULL || length != 1 || values[0] < 1 || values[0] > MAX_DIMENSION)
        return INVALID_RESULT;
    const int n = (int)values[0];
    double a[MAX_CELLS], product[MAX_CELLS], b[MAX_DIMENSION], x[MAX_DIMENSION], y[MAX_DIMENSION];
    for (int i = 0; i < n; ++i) {
        x[i] = 0.0;
        y[i] = 0.0;
        b[i] = ((double)(i + 1) / (double)n) / 2.0 + 4.0;
    }
    for (int i = 0; i < n; ++i) {
        for (int j = 0; j <= i; ++j)
            a[i * n + j] = (double)(-(int64_t)j % (int64_t)n) / (double)n + 1.0;
        for (int j = i + 1; j < n; ++j) a[i * n + j] = 0.0;
        a[i * n + i] = 1.0;
    }
    for (int r = 0; r < n; ++r)
        for (int s = 0; s < n; ++s) product[r * n + s] = 0.0;
    for (int t = 0; t < n; ++t)
        for (int r = 0; r < n; ++r)
            for (int s = 0; s < n; ++s)
                product[r * n + s] = product[r * n + s] + a[r * n + t] * a[s * n + t];
    for (int r = 0; r < n; ++r)
        for (int s = 0; s < n; ++s) a[r * n + s] = product[r * n + s];

    for (int i = 0; i < n; ++i) {
        for (int j = 0; j < i; ++j) {
            double w = a[i * n + j];
            for (int k = 0; k < j; ++k) w = w - a[i * n + k] * a[k * n + j];
            a[i * n + j] = w / a[j * n + j];
        }
        for (int j = i; j < n; ++j) {
            double w = a[i * n + j];
            for (int k = 0; k < i; ++k) w = w - a[i * n + k] * a[k * n + j];
            a[i * n + j] = w;
        }
    }
    for (int i = 0; i < n; ++i) {
        double w = b[i];
        for (int j = 0; j < i; ++j) w = w - a[i * n + j] * y[j];
        y[i] = w;
    }
    for (int i = n - 1; i >= 0; --i) {
        double w = y[i];
        for (int j = i + 1; j < n; ++j) w = w - a[i * n + j] * x[j];
        x[i] = w / a[i * n + i];
    }
    double result = 0.0;
    for (int i = 0; i < n; ++i) result += x[i];
    return result;
}
