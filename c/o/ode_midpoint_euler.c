#include <stddef.h>
#include <stdint.h>
#include <string.h>

#define MAX_STEPS 8
#define OUTPUT_BYTES 16

static void put_f64_le(uint8_t *output, size_t offset, double value) {
    uint64_t bits;
    memcpy(&bits, &value, sizeof(bits));
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t ode_midpoint_euler(const int64_t *input, size_t length,
                           uint8_t *output, size_t capacity) {
    if (input == NULL || length != 4) return -1;
    const int64_t steps = input[0];
    const int64_t dt_quarters = input[1];
    const int64_t u0 = input[2];
    const int64_t v0 = input[3];
    if (steps < 1 || steps > MAX_STEPS || dt_quarters < 1 || dt_quarters > 4 ||
        u0 < -10 || u0 > 10 || v0 < -10 || v0 > 10) return -1;
    if (output == NULL || capacity < OUTPUT_BYTES) return -2;

    const double dt = (double)dt_quarters / 4.0;
    const double half_dt = 0.5 * dt;
    double u = (double)u0;
    double v = (double)v0;
    for (int64_t step = 0; step < steps; ++step) {
        const double midpoint_u = u + half_dt * v;
        const double midpoint_v = v - half_dt * u;
        const double next_u = u + dt * midpoint_v;
        const double next_v = v - dt * midpoint_u;
        u = next_u;
        v = next_v;
    }
    put_f64_le(output, 0, u);
    put_f64_le(output, 8, v);
    return OUTPUT_BYTES;
}
