#include <math.h>
#include <stddef.h>
#include <stdint.h>

int64_t simple_pendulum_rk4(const double *values, size_t length,
                            double *output, size_t capacity) {
    if (values == NULL || length != 5) return -1;
    const double minimums[5] = {10000.0, 100000.0, -3141593.0, -100000000.0, 1.0};
    const double maximums[5] = {100000000.0, 20000000.0, 3141593.0, 100000000.0, 100000.0};
    for (size_t i = 0; i < 5; ++i) {
        if (!isfinite(values[i]) || trunc(values[i]) != values[i] ||
            values[i] < minimums[i] || values[i] > maximums[i]) return -1;
    }

    const double length_m = values[0] / 1000000.0;
    const double gravity = values[1] / 1000000.0;
    const double theta = values[2] / 1000000.0;
    const double omega = values[3] / 1000000.0;
    const double dt = values[4] / 1000000.0;
    const double acceleration_scale = gravity / length_m;

    const double k1_theta = omega;
    const double k1_omega = -acceleration_scale * sin(theta);
    const double k2_theta = omega + 0.5 * dt * k1_omega;
    const double k2_omega = -acceleration_scale * sin(theta + 0.5 * dt * k1_theta);
    const double k3_theta = omega + 0.5 * dt * k2_omega;
    const double k3_omega = -acceleration_scale * sin(theta + 0.5 * dt * k2_theta);
    const double k4_theta = omega + dt * k3_omega;
    const double k4_omega = -acceleration_scale * sin(theta + dt * k3_theta);
    const double theta_next = theta + dt / 6.0 *
        (k1_theta + 2.0 * k2_theta + 2.0 * k3_theta + k4_theta);
    const double omega_next = omega + dt / 6.0 *
        (k1_omega + 2.0 * k2_omega + 2.0 * k3_omega + k4_omega);

    if (output == NULL || capacity < 2) return -2;
    output[0] = theta_next;
    output[1] = omega_next;
    return 2;
}
