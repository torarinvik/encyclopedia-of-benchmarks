#include <math.h>
#include <stddef.h>

#define MAX_N 64

long long tsvc_s111_odd_index_neighbor_update(const double *input, size_t length,
                                               double *output, size_t capacity) {
    if (input == NULL || length < 3 || length > 129) return -1;
    double raw_n = input[0];
    if (!isfinite(raw_n) || trunc(raw_n) != raw_n || raw_n < 1 || raw_n > MAX_N) return -1;
    size_t n = (size_t)raw_n;
    if (length != 1 + 2 * n) return -1;
    for (size_t i = 1; i < length; ++i)
        if (!isfinite(input[i]) || trunc(input[i]) != input[i] || fabs(input[i]) > 1000) return -1;
    if (output == NULL || capacity < n) return -2;
    for (size_t i = 0; i < n; ++i) output[i] = input[1 + i];
    for (size_t i = 1; i < n; i += 2) output[i] = input[i] + input[1 + n + i];
    return (long long)n;
}
