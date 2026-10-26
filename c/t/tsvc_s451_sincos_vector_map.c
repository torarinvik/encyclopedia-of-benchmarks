#include <math.h>
#include <stddef.h>

long long tsvc_s451_sincos_vector_map(const double *input, size_t length,
                                       double *output, size_t capacity) {
    if (input == NULL || length < 3 || length > 129) return -1;
    const double rn = input[0];
    if (!isfinite(rn) || trunc(rn) != rn || rn < 1 || rn > 64) return -1;
    const size_t n = (size_t)rn;
    if (length != 1 + 2*n) return -1;
    for (size_t i = 1; i < length; ++i)
        if (!isfinite(input[i]) || fabs(input[i]) > 10) return -1;
    if (output == NULL || capacity < n) return -2;
    for (size_t i = 0; i < n; ++i) output[i] = sin(input[1+i]) + cos(input[1+n+i]);
    return (long long)n;
}
