#include <math.h>
#include <stddef.h>

long long tsvc_s221_partial_recursive_fused_update(const double *input, size_t length,
                                                    double *output, size_t capacity) {
    if (input == NULL || length < 5 || length > 257) return -1;
    const double rn = input[0];
    if (!isfinite(rn) || trunc(rn) != rn || rn < 1 || rn > 64) return -1;
    const size_t n = (size_t)rn;
    if (length != 1 + 4*n) return -1;
    for (size_t i = 1; i < length; ++i)
        if (!isfinite(input[i]) || trunc(input[i]) != input[i] || fabs(input[i]) > 2) return -1;
    const size_t required = 2*n;
    if (output == NULL || capacity < required) return -2;
    for (size_t i = 0; i < n; ++i) {
        output[i] = input[1+i];
        output[n+i] = input[1+n+i];
    }
    for (size_t i = 1; i < n; ++i) {
        output[i] = output[i] + input[1+2*n+i] * input[1+3*n+i];
        output[n+i] = (output[n+i-1] + output[i]) + input[1+3*n+i];
    }
    return (long long)required;
}
