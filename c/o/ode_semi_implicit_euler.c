#include <stddef.h>
#include <stdint.h>

static void store_f64_le(uint8_t *output, size_t offset, double value)
{
    union { double f; uint64_t u; } bits = { .f = value };
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits.u & UINT64_C(255));
        bits.u >>= 8;
    }
}

int64_t ode_semi_implicit_euler(const int64_t *values, size_t length,
                          uint8_t *output, size_t output_capacity)
{
    if (values == NULL || length != 4) return -1;
    if (values[0] < 1 || values[0] > 8 || values[1] < 1 || values[1] > 4 ||
        values[2] < -10 || values[2] > 10 || values[3] < -10 || values[3] > 10) return -1;
    if (output == NULL || output_capacity < 16) return -2;
    const double dt = (double)values[1] / 4.0;
    double u = (double)values[2], v = (double)values[3];
    for (int64_t step = 0; step < values[0]; ++step) {
        const double old_u = u, old_v = v;
        u = old_u + dt * old_v;
        v = old_v - dt * u;
    }
    store_f64_le(output, 0, u);
    store_f64_le(output, 8, v);
    return 16;
}
