#include <math.h>
#include <stddef.h>
#include <stdint.h>

enum { MAX_PAIRS = 64, OUTPUT_ELEMENTS = 2 * MAX_PAIRS };
#define MAX_DRAW 4294967295.0
#define DRAW_SCALE 4294967296.0
#define TAU 6.283185307179586476925286766559

static int is_bounded_integer(double value, double minimum, double maximum) {
    return isfinite(value) && trunc(value) == value && value >= minimum && value <= maximum;
}

int64_t box_muller_cartesian_normal(const double *input, size_t length,
                                   double *output, size_t capacity) {
    if (input == NULL || length < 2 || length > 1 + 2 * MAX_PAIRS) return -1;
    if (!is_bounded_integer(input[0], 1.0, MAX_PAIRS)) return -1;
    const size_t pair_count = (size_t)input[0];
    if (length != 1 + 2 * pair_count) return -1;
    for (size_t index = 0; index < 2 * pair_count; ++index)
        if (!is_bounded_integer(input[1 + index], 0.0, MAX_DRAW)) return -1;

    const size_t result_count = 2 * pair_count;
    if (output == NULL || capacity < result_count) return -2;
    for (size_t pair = 0; pair < pair_count; ++pair) {
        const double radial = (input[1 + 2 * pair] + 1.0) / DRAW_SCALE;
        const double angular = input[2 + 2 * pair] / DRAW_SCALE;
        const double radius = sqrt(-2.0 * log(radial));
        const double angle = TAU * angular;
        output[2 * pair] = radius * cos(angle);
        output[2 * pair + 1] = radius * sin(angle);
    }
    return (int64_t)result_count;
}
