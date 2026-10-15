#include <stddef.h>
#include <stdint.h>

#define MAX_COORD INT64_C(128)
#define MAX_STEPS INT64_C(256)
static int64_t java_round(double value) {
    const double shifted = value + 0.5;
    int64_t rounded = (int64_t)shifted;
    if ((double)rounded > shifted) --rounded;
    return rounded;
}
static void write_i64(uint8_t *output, size_t *position, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (unsigned shift = 0; shift < 64; shift += 8) output[(*position)++] = (uint8_t)(bits >> shift);
}
int64_t ddaline(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length != 4) return -1;
    for (size_t i = 0; i < 4; ++i) if (input[i] < -MAX_COORD || input[i] > MAX_COORD) return -1;
    const int64_t dx = input[2] - input[0], dy = input[3] - input[1];
    const int64_t ax = dx < 0 ? -dx : dx, ay = dy < 0 ? -dy : dy;
    const int64_t steps = ax > ay ? ax : ay;
    if (steps > MAX_STEPS) return -1;
    const size_t point_count = (size_t)steps + 1;
    const size_t output_bytes = point_count * 16;
    if (output == NULL || capacity < output_bytes) return -2;
    if (steps == 0) {
        size_t position = 0;
        write_i64(output, &position, input[0]);
        write_i64(output, &position, input[1]);
        return 16;
    }
    const double x_inc = (double)dx / (double)steps, y_inc = (double)dy / (double)steps;
    double x = (double)input[0], y = (double)input[1];
    size_t position = 0;
    for (int64_t i = 0; i <= steps; ++i) {
        write_i64(output, &position, java_round(x));
        write_i64(output, &position, java_round(y));
        x += x_inc;
        y += y_inc;
    }
    return (int64_t)output_bytes;
}
