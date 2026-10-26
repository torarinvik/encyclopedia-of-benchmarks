#include <math.h>
#include <stddef.h>

#define MAX_N 8

long long tsvc_s275_column_conditional_axpy_recurrence(const double *input, size_t length,
                                                       double *output, size_t capacity) {
    if (input == NULL || length < 2 || length > 193) return -1;
    double raw_n = input[0];
    if (!isfinite(raw_n) || trunc(raw_n) != raw_n || raw_n < 1 || raw_n > MAX_N) return -1;
    size_t n = (size_t)raw_n, cells = n * n;
    if (length != 1 + 3 * cells) return -1;
    for (size_t i = 1; i < length; ++i)
        if (!isfinite(input[i]) || trunc(input[i]) != input[i] || fabs(input[i]) > 16) return -1;
    if (output == NULL || capacity < cells) return -2;
    double a[MAX_N * MAX_N];
    for (size_t i = 0; i < cells; ++i) a[i] = input[1 + i];
    const size_t b_start = 1 + cells, c_start = 1 + 2 * cells;
    for (size_t col = 0; col < n; ++col) {
        if (a[col] > 0.0) {
            for (size_t row = 1; row < n; ++row) {
                size_t index = row * n + col;
                a[index] = a[index - n] + input[b_start + index] * input[c_start + index];
            }
        }
    }
    for (size_t i = 0; i < cells; ++i) output[i] = a[i];
    return (long long)cells;
}
