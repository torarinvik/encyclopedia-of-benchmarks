#include <stddef.h>
#include <stdint.h>
#include <string.h>

static void put_f64_le(double value, uint8_t *output, size_t offset) {
    uint64_t bits; memcpy(&bits, &value, sizeof(bits));
    for (size_t byte = 0; byte < 8; ++byte) output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t euler_method_julia(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (!input || length != 3 || input[0] < -8 || input[0] > 8 || input[1] < 1 || input[1] > 16 || input[2] < 1 || input[2] > 4) return -1;
    const size_t steps = (size_t)input[1], required = 16 * steps;
    if (!output || capacity < required) return -2;
    double states[16], times[16]; states[0] = (double)input[0]; times[0] = 0.0;
    const double h = 1.0 / (double)(1 << input[2]);
    for (size_t i = 0; i + 1 < steps; ++i) {
        states[i + 1] = states[i] + h * (states[i] + times[i]);
        times[i + 1] = times[i] + h;
    }
    for (size_t i = 0; i < steps; ++i) { put_f64_le(states[i], output, 8 * i); put_f64_le(times[i], output, 8 * (steps + i)); }
    return (int64_t)required;
}
