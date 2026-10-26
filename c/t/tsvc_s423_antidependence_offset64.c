#include <stddef.h>
#include <stdint.h>

int64_t tsvc_s423_antidependence_offset64(const int64_t *input, size_t length) {
    enum { MIN_N = 65, MAX_N = 128, MAX_INPUT = MAX_N + 65, X_LENGTH = MAX_N + 64 };
    if (input == NULL || length < MIN_N + 65 || length > MAX_INPUT) return -1;
    if (input[0] < MIN_N || input[0] > MAX_N) return -1;
    const size_t n = (size_t)input[0];
    if (length != n + 65) return -1;
    int64_t a[MAX_N];
    int64_t x[X_LENGTH] = {0};
    for (size_t i = 0; i < n; ++i) {
        a[i] = input[1+i];
        if (a[i] < 0 || a[i] > 2) return -1;
    }
    for (size_t i = 0; i < 64; ++i) {
        x[i] = input[1+n+i];
        if (x[i] < 0 || x[i] > 2) return -1;
    }
    for (size_t i = 64; i < n + 64; ++i) x[i] = 1;
    for (size_t i = 0; i < n - 1; ++i) x[i+1] = x[i+64] + a[i];
    int64_t sum = 0;
    for (size_t i = 0; i < n; ++i) sum += x[i];
    return sum;
}
