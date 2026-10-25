#include <stddef.h>
#include <stdint.h>

#define MIN_N 2
#define MAX_N 8
#define MIN_PASSES 1
#define MAX_PASSES 4

int64_t tsvc_s257_column_coupled_update(const int64_t *values, size_t length)
{
    if (values == NULL || length < 12 || length > 2 + MAX_N + 2 * MAX_N * MAX_N) return -1;
    const int64_t n_value = values[0];
    const int64_t passes_value = values[1];
    if (n_value < MIN_N || n_value > MAX_N ||
        passes_value < MIN_PASSES || passes_value > MAX_PASSES) return -1;
    const size_t n = (size_t)n_value;
    const size_t passes = (size_t)passes_value;
    if (length != 2 + n + 2 * n * n) return -1;
    for (size_t index = 2; index < length; ++index) {
        if (values[index] < -1 || values[index] > 1) return -1;
    }

    int64_t a[MAX_N];
    int64_t aa[MAX_N * MAX_N];
    int64_t bb[MAX_N * MAX_N];
    for (size_t i = 0; i < n; ++i) a[i] = values[2 + i];
    const size_t aa_start = 2 + n;
    const size_t bb_start = aa_start + n * n;
    for (size_t i = 0; i < n * n; ++i) {
        aa[i] = values[aa_start + i];
        bb[i] = values[bb_start + i];
    }

    for (size_t pass = 0; pass < passes; ++pass) {
        for (size_t i = 1; i < n; ++i) {
            for (size_t j = 0; j < n; ++j) {
                const size_t cell = j * n + i;
                a[i] = aa[cell] - a[i - 1];
                aa[cell] = a[i] + bb[cell];
            }
        }
    }

    int64_t checksum = 0;
    for (size_t i = 0; i < n; ++i) checksum += a[i];
    for (size_t i = 0; i < n * n; ++i) checksum += aa[i];
    return checksum;
}
