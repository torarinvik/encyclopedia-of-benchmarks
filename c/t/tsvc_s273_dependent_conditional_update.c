#include <stddef.h>
#include <stdint.h>

#define MAX_N 64
#define MAX_PASSES 8

int64_t tsvc_s273_dependent_conditional_update(const int64_t *values, size_t length)
{
    if (values == NULL || length < 7 || length > 2 + 5 * MAX_N) return -1;
    const int64_t n_value = values[0];
    const int64_t passes_value = values[1];
    if (n_value < 1 || n_value > MAX_N || passes_value < 1 || passes_value > MAX_PASSES) return -1;
    const size_t n = (size_t)n_value;
    const size_t passes = (size_t)passes_value;
    if (length != 2 + 5 * n) return -1;
    for (size_t index = 2; index < length; ++index) {
        if (values[index] < -2 || values[index] > 2) return -1;
    }

    int64_t a[MAX_N], b[MAX_N], c[MAX_N], d[MAX_N], e[MAX_N];
    for (size_t i = 0; i < n; ++i) {
        a[i] = values[2 + i];
        b[i] = values[2 + n + i];
        c[i] = values[2 + 2 * n + i];
        d[i] = values[2 + 3 * n + i];
        e[i] = values[2 + 4 * n + i];
    }

    for (size_t pass = 0; pass < passes; ++pass) {
        for (size_t i = 0; i < n; ++i) {
            a[i] += d[i] * e[i];
            if (a[i] < 0) b[i] += d[i] * e[i];
            c[i] += a[i] * d[i];
        }
    }

    int64_t checksum = 0;
    for (size_t i = 0; i < n; ++i) checksum += a[i] + b[i] + c[i];
    return checksum;
}
