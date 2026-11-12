#include <math.h>
#include <stddef.h>
#include <stdint.h>
#include <string.h>

enum { MAX_PARTICLES = 32, MAX_INPUT_LENGTH = 2 + 6 * MAX_PARTICLES };
static const double PI = 3.14159265358979323846264338327950288;

static void store_f64_le(uint8_t *output, size_t offset, double value) {
    uint64_t bits;
    memcpy(&bits, &value, sizeof(bits));
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t fluidanimate_sph(const int64_t *input, size_t length,
                         uint8_t *output, size_t capacity) {
    if (!input || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t count_value = input[0], rpm_milli = input[1];
    if (count_value < 1 || count_value > MAX_PARTICLES || rpm_milli < 500 || rpm_milli > 5000)
        return -1;
    const size_t count = (size_t)count_value;
    if (length != 2 + 6 * count) return -1;
    for (size_t i = 0; i < count; ++i) {
        const size_t base = 2 + 6 * i;
        for (size_t axis = 0; axis < 3; ++axis)
            if (input[base + axis] < -10000 || input[base + axis] > 10000) return -1;
        for (size_t axis = 3; axis < 6; ++axis)
            if (input[base + axis] < -5000 || input[base + axis] > 5000) return -1;
    }
    const size_t output_bytes = 40 * count;
    if (!output || capacity < output_bytes) return -2;

    double position[MAX_PARTICLES][3], velocity[MAX_PARTICLES][3];
    double density[MAX_PARTICLES], acceleration[MAX_PARTICLES][3];
    const double rpm = (double)rpm_milli / 1000.0;
    const double h = 1.695 / rpm, h2 = h * h;
    const double mass = 1000.0 / (rpm * rpm * rpm);
    const double density_coeff = mass * (315.0 / (64.0 * PI * pow(h, 9.0)));
    const double pressure_coeff = 3.0 * (15.0 / (PI * pow(h, 6.0))) * 1.5 * mass;
    const double viscosity_coeff = 0.4 * (45.0 / (PI * pow(h, 6.0))) * mass;

    for (size_t i = 0; i < count; ++i) {
        const size_t base = 2 + 6 * i;
        for (size_t axis = 0; axis < 3; ++axis) {
            position[i][axis] = (double)input[base + axis] / 1000.0;
            velocity[i][axis] = (double)input[base + 3 + axis] / 1000.0;
            acceleration[i][axis] = axis == 1 ? -9.8 : 0.0;
        }
        density[i] = density_coeff * h2 * h2 * h2;
    }
    for (size_t i = 0; i < count; ++i) {
        for (size_t j = i + 1; j < count; ++j) {
            const double dx = position[i][0] - position[j][0];
            const double dy = position[i][1] - position[j][1];
            const double dz = position[i][2] - position[j][2];
            const double r2 = dx * dx + dy * dy + dz * dz;
            if (r2 < h2) {
                const double term = density_coeff * pow(h2 - r2, 3.0);
                density[i] += term;
                density[j] += term;
            }
        }
    }
    for (size_t i = 0; i < count; ++i) {
        for (size_t j = i + 1; j < count; ++j) {
            const double dx = position[i][0] - position[j][0];
            const double dy = position[i][1] - position[j][1];
            const double dz = position[i][2] - position[j][2];
            const double r2 = dx * dx + dy * dy + dz * dz;
            if (r2 >= h2) continue;
            const double distance = sqrt(fmax(r2, 1e-12));
            const double hmr = h - distance;
            const double rho_product = density[i] * density[j];
            const double pressure_scale = pressure_coeff * (hmr * hmr / distance)
                * (density[i] + density[j] - 2000.0) / rho_product;
            const double viscosity_scale = viscosity_coeff * hmr / rho_product;
            const double displacement[3] = {dx, dy, dz};
            for (size_t axis = 0; axis < 3; ++axis) {
                const double force = displacement[axis] * pressure_scale
                    + (velocity[j][axis] - velocity[i][axis]) * viscosity_scale;
                acceleration[i][axis] += force;
                acceleration[j][axis] -= force;
            }
        }
    }
    for (size_t i = 0; i < count; ++i) {
        const double result[5] = {density[i], 3.0 * (density[i] - 1000.0),
            acceleration[i][0], acceleration[i][1], acceleration[i][2]};
        for (size_t field = 0; field < 5; ++field)
            store_f64_le(output, 8 * (5 * i + field), result[field]);
    }
    return (int64_t)output_bytes;
}
