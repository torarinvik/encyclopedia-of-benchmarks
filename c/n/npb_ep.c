#include <math.h>
#include <stddef.h>
#include <stdint.h>

enum { MAX_PAIRS = 4096, HISTOGRAM_BINS = 10, OUTPUT_ELEMENTS = 12 };
#define MODULUS_MASK UINT64_C(70368744177663)
#define WORD_MASK UINT64_C(8388607)
#define MULTIPLIER UINT64_C(1220703125)
#define MULTIPLIER_LOW (MULTIPLIER & WORD_MASK)
#define MULTIPLIER_HIGH (MULTIPLIER >> 23)
#define MODULUS_SCALE 70368744177664.0

static int is_bounded_integer(double value, double minimum, double maximum) {
    return isfinite(value) && trunc(value) == value && value >= minimum && value <= maximum;
}

static uint64_t advance_state(uint64_t state) {
    const uint64_t low = state & WORD_MASK;
    const uint64_t high = state >> 23;
    const uint64_t low_product = low * MULTIPLIER_LOW;
    const uint64_t cross = (low * MULTIPLIER_HIGH + high * MULTIPLIER_LOW) & WORD_MASK;
    return (low_product + (cross << 23)) & MODULUS_MASK;
}

int64_t npb_ep(const double *input, size_t length,
               double *output, size_t capacity) {
    if (input == NULL || length != 2 ||
        !is_bounded_integer(input[0], 1.0, MAX_PAIRS) ||
        !is_bounded_integer(input[1], 1.0, 70368744177663.0)) return -1;
    const size_t pair_count = (size_t)input[0];
    if (output == NULL || capacity < OUTPUT_ELEMENTS) return -2;

    uint64_t state = (uint64_t)input[1];
    uint64_t histogram[HISTOGRAM_BINS] = {0};
    double sum_x = 0.0, sum_y = 0.0;
    for (size_t pair = 0; pair < pair_count; ++pair) {
        state = advance_state(state);
        const double x = 2.0 * ((double)state / MODULUS_SCALE) - 1.0;
        state = advance_state(state);
        const double y = 2.0 * ((double)state / MODULUS_SCALE) - 1.0;
        const double radius_squared = x * x + y * y;
        if (radius_squared <= 0.0 || radius_squared > 1.0) continue;
        const double scale = sqrt(-2.0 * log(radius_squared) / radius_squared);
        const double normal_x = x * scale, normal_y = y * scale;
        const double extent = fmax(fabs(normal_x), fabs(normal_y));
        if (extent < HISTOGRAM_BINS) ++histogram[(size_t)extent];
        sum_x += normal_x;
        sum_y += normal_y;
    }
    for (size_t bin = 0; bin < HISTOGRAM_BINS; ++bin) output[bin] = (double)histogram[bin];
    output[10] = sum_x;
    output[11] = sum_y;
    return OUTPUT_ELEMENTS;
}
