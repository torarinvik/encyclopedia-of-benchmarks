/* Clean-room port of TSVC s258; provenance and rights are in package README. */
#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 64, MAX_INPUT_LENGTH = 1 + 4 * MAX_N };

int64_t tsvc_s258_wrapped_scalar_expansion(const int64_t *input, size_t length) {
    if (input == NULL || length < 5 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 1 || input[0] > MAX_N) return -1;
    const size_t n = (size_t)input[0];
    if (length != 1 + 4 * n) return -1;
    int64_t a[MAX_N], c[MAX_N], d[MAX_N], aa0[MAX_N], b[MAX_N], e[MAX_N];
    const size_t c_start = 1 + n;
    const size_t d_start = 1 + 2 * n;
    const size_t aa_start = 1 + 3 * n;
    for (size_t i = 0; i < n; ++i) {
        a[i] = input[1 + i];
        c[i] = input[c_start + i];
        d[i] = input[d_start + i];
        aa0[i] = input[aa_start + i];
        if (a[i] < 0 || a[i] > 2 || c[i] < 0 || c[i] > 2 ||
            d[i] < 0 || d[i] > 2 || aa0[i] < 0 || aa0[i] > 2) return -1;
    }
    int64_t s = 0;
    for (size_t i = 0; i < n; ++i) {
        if (a[i] > 0) s = d[i] * d[i];
        b[i] = s * c[i] + d[i];
        e[i] = (s + 1) * aa0[i];
    }
    int64_t sum_b = 0, sum_e = 0;
    for (size_t i = 0; i < n; ++i) sum_b += b[i];
    for (size_t i = 0; i < n; ++i) sum_e += e[i];
    return sum_b + sum_e;
}
