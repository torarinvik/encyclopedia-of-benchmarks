#include <math.h>
#include <stddef.h>
#include <stdint.h>

enum { MAX_DRAWS = 128, MAX_ATTEMPTS = 64, OUTPUT_ELEMENTS = 2 };
#define MAX_DRAW_VALUE 4294967295.0
#define DRAW_SCALE 2147483648.0

static int is_bounded_integer(double value, double minimum, double maximum) {
    return isfinite(value) && trunc(value) == value && value >= minimum && value <= maximum;
}

int64_t marsaglia_polar_normal(const double *input, size_t length,
                               double *output, size_t capacity) {
    if (input == NULL || length < 4 || length > 2 + MAX_DRAWS) return -1;
    if (!is_bounded_integer(input[0], 2.0, MAX_DRAWS) ||
        !is_bounded_integer(input[1], 1.0, MAX_ATTEMPTS)) return -1;
    const size_t draw_count = (size_t)input[0];
    const size_t attempt_cap = (size_t)input[1];
    if ((draw_count & 1U) != 0 || length != 2 + draw_count ||
        draw_count < 2 * attempt_cap) return -1;
    for (size_t index = 0; index < draw_count; ++index)
        if (!is_bounded_integer(input[2 + index], 0.0, MAX_DRAW_VALUE)) return -1;

    double first = 0.0, second = 0.0;
    int accepted = 0;
    for (size_t attempt = 0; attempt < attempt_cap; ++attempt) {
        const double u1 = input[2 + 2 * attempt] / DRAW_SCALE - 1.0;
        const double u2 = input[3 + 2 * attempt] / DRAW_SCALE - 1.0;
        const double radius_squared = u1 * u1 + u2 * u2;
        if (radius_squared <= 0.0 || radius_squared >= 1.0) continue;
        const double scale = sqrt(-2.0 * log(radius_squared) / radius_squared);
        first = u1 * scale;
        second = u2 * scale;
        accepted = 1;
        break;
    }
    if (!accepted) return -1;
    if (output == NULL || capacity < OUTPUT_ELEMENTS) return -2;
    output[0] = first;
    output[1] = second;
    return OUTPUT_ELEMENTS;
}
