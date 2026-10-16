#include <math.h>
#include <stddef.h>
#include <stdint.h>

int64_t softmax(const double *values, size_t length, double *output, size_t capacity)
{
    if (values == NULL || length == 0 || length > 64) return -1;
    for (size_t i = 0; i < length; ++i) {
        if (!isfinite(values[i]) || values[i] < -20.0 || values[i] > 20.0) return -1;
    }
    if (output == NULL || capacity < length) return -2;

    double total = 0.0;
    for (size_t i = 0; i < length; ++i) total += exp(values[i]);
    for (size_t i = 0; i < length; ++i) output[i] = exp(values[i]) / total;
    return (int64_t)length;
}
