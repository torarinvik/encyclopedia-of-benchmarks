#include <stddef.h>
#include <stdint.h>

#define MAX_N 128

int64_t tsvc_vbor(const int64_t *values, size_t length)
{
    if (values == NULL || length < 7 || length > 1 + 6 * MAX_N) return -1;
    const int64_t n_value = values[0];
    if (n_value < 1 || n_value > MAX_N) return -1;
    const size_t n = (size_t)n_value;
    if (length != 1 + 6 * n) return -1;
    for (size_t index = 1; index < length; ++index) {
        if (values[index] < 0 || values[index] > 2) return -1;
    }

    int64_t checksum = 0;
    for (size_t i = 0; i < n; ++i) {
        const int64_t a = values[1 + i];
        const int64_t b = values[1 + n + i];
        const int64_t c = values[1 + 2 * n + i];
        const int64_t d = values[1 + 3 * n + i];
        const int64_t e = values[1 + 4 * n + i];
        const int64_t f = values[1 + 5 * n + i];

        const int64_t a1 = a * b * c + a * b * d + a * b * e + a * b * f
            + a * c * d + a * c * e + a * c * f + a * d * e + a * d * f + a * e * f;
        const int64_t b1 = b * c * d + b * c * e + b * c * f + b * d * e + b * d * f + b * e * f;
        const int64_t c1 = c * d * e + c * d * f + c * e * f;
        const int64_t d1 = d * e * f;
        checksum += a1 * b1 * c1 * d1;
    }
    return checksum;
}
