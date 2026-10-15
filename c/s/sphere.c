#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT (-1.0e300)
double sphere(const int64_t *input, size_t length) {
    if (input == NULL || length != 2) return INVALID_RESULT;
    const int64_t mode = input[0], radius = input[1];
    if ((mode != 0 && mode != 1) || radius < 0 || radius > 1000000) return INVALID_RESULT;
    const double r = (double)radius;
    const double r2 = r * r;
    if (mode == 0) return (((r2 * r) * 3.14159265358979323846) * 4.0) / 3.0;
    return (r2 * 3.14159265358979323846) * 4.0;
}
