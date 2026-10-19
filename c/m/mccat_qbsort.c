#include <stddef.h>
#include <stdint.h>

#define MAX_ITEMS 32

static void bubble(int32_t *a, size_t n) {
    for (size_t end = n; end > 1; --end)
        for (size_t i = 0; i + 1 < end; ++i)
            if (a[i + 1] < a[i]) { int32_t t = a[i]; a[i] = a[i + 1]; a[i + 1] = t; }
}

static void quick(int32_t *a, size_t n) {
    if (n < 2) return;
    const int32_t pivot = a[0];
    int32_t lower[MAX_ITEMS], upper[MAX_ITEMS];
    size_t nl = 0, nu = 0;
    for (size_t i = 1; i < n; ++i) {
        if (a[i] < pivot) lower[nl++] = a[i]; else upper[nu++] = a[i];
    }
    quick(upper, nu); quick(lower, nl);
    size_t k = 0;
    for (size_t i = 0; i < nl; ++i) a[k++] = lower[i];
    a[k++] = pivot;
    for (size_t i = 0; i < nu; ++i) a[k++] = upper[i];
}

int64_t mccat_qbsort(const int64_t *input, size_t length, uint8_t *output, size_t output_capacity) {
    if (input == NULL || length < 3 || length > 2 + MAX_ITEMS) return -1;
    const int64_t mode = input[0], count_value = input[1];
    if ((mode != 0 && mode != 1) || count_value < 1 || count_value > MAX_ITEMS) return -1;
    const size_t n = (size_t)count_value;
    if (length != n + 2) return -1;
    int32_t values[MAX_ITEMS];
    for (size_t i = 0; i < n; ++i) {
        if (input[i + 2] < INT32_MIN || input[i + 2] > INT32_MAX) return -1;
        values[i] = (int32_t)input[i + 2];
    }
    for (size_t pass = 0; pass < 1000; ++pass) {
        for (size_t i = 0; i < n; ++i) values[i] = (int32_t)input[i + 2];
        if (mode == 0) bubble(values, n); else quick(values, n);
    }
    const size_t required = 4 * n;
    if (output == NULL || output_capacity < required) return -2;
    for (size_t i = 0; i < n; ++i) {
        uint32_t bits = (uint32_t)values[i];
        for (size_t b = 0; b < 4; ++b) output[4 * i + b] = (uint8_t)(bits >> (8 * b));
    }
    return (int64_t)required;
}
