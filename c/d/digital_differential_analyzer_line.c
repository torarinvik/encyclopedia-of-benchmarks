/* Incremental floating-point DDA line points encoded as little-endian i32 pairs. */
#include <stddef.h>
#include <stdint.h>

#define MAX_COORDINATE INT64_C(1000000)
#define MAX_STEPS INT64_C(4096)

static int64_t round_ties_to_even(double value)
{
    int64_t lower = (int64_t)value;
    if ((double)lower > value) --lower;
    const double fraction = value - (double)lower;
    if (fraction > 0.5 || (fraction == 0.5 && lower % 2 != 0)) ++lower;
    return lower;
}

static void write_i32_le(uint8_t *output, size_t *position, int64_t value)
{
    const uint32_t bits = (uint32_t)(int32_t)value;
    for (unsigned shift = 0; shift < 32; shift += 8) output[(*position)++] = (uint8_t)(bits >> shift);
}

int64_t digital_differential_analyzer_line(const int64_t *values, size_t length,
                                            uint8_t *output, size_t output_capacity)
{
    if (length != 4) return -1;
    for (size_t i = 0; i < 4; ++i)
        if (values[i] < -MAX_COORDINATE || values[i] > MAX_COORDINATE) return -1;
    const int64_t dx = values[2] - values[0], dy = values[3] - values[1];
    const int64_t abs_dx = dx < 0 ? -dx : dx, abs_dy = dy < 0 ? -dy : dy;
    const int64_t steps = abs_dx > abs_dy ? abs_dx : abs_dy;
    if (steps == 0 || steps > MAX_STEPS) return -1;
    const size_t output_bytes = (size_t)steps * 8;
    if (output_capacity < output_bytes || output == NULL) return -2;
    const double x_increment = (double)dx / (double)steps;
    const double y_increment = (double)dy / (double)steps;
    double x = (double)values[0], y = (double)values[1];
    size_t position = 0;
    for (int64_t step = 0; step < steps; ++step) {
        x += x_increment;
        y += y_increment;
        write_i32_le(output, &position, round_ties_to_even(x));
        write_i32_le(output, &position, round_ties_to_even(y));
    }
    return (int64_t)output_bytes;
}
