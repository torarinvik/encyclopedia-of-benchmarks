#include <math.h>
#include <stddef.h>

long long tsvc_vtvtv_triple_product_map(const double *input, size_t length,
                                        double *output, size_t capacity) {
    if (input == NULL || length < 4 || length > 193) return -1;
    double raw_n = input[0];
    if (!isfinite(raw_n) || trunc(raw_n) != raw_n || raw_n < 1 || raw_n > 64) return -1;
    size_t n = (size_t)raw_n;
    if (length != 1 + 3 * n) return -1;
    for (size_t i = 1; i < length; ++i)
        if (!isfinite(input[i]) || trunc(input[i]) != input[i] || fabs(input[i]) > 2) return -1;
    if (output == NULL || capacity < n) return -2;
    for (size_t i = 0; i < n; ++i) output[i] = (input[1+i] * input[1+n+i]) * input[1+2*n+i];
    return (long long)n;
}
