module simple_pendulum_rk4;

extern fn double sin(double value);
extern fn double floor(double value);

fn long simple_pendulum_rk4(double* values, usz length,
                            double* output, usz capacity) @export("simple_pendulum_rk4") {
    if (values == null || length != 5) return -1;
    for (usz i = 0; i < 5; i++) {
        if (values[i] != values[i] || floor(values[i]) != values[i]) return -1;
    }
    if (values[0] < 10000.0 || values[0] > 100000000.0 ||
        values[1] < 100000.0 || values[1] > 20000000.0 ||
        values[2] < -3141593.0 || values[2] > 3141593.0 ||
        values[3] < -100000000.0 || values[3] > 100000000.0 ||
        values[4] < 1.0 || values[4] > 100000.0) return -1;

    double length_m = values[0] / 1000000.0;
    double gravity = values[1] / 1000000.0;
    double theta = values[2] / 1000000.0;
    double omega = values[3] / 1000000.0;
    double dt = values[4] / 1000000.0;
    double scale = gravity / length_m;

    double k1_theta = omega;
    double k1_omega = -scale * sin(theta);
    double k2_theta = omega + 0.5 * dt * k1_omega;
    double k2_omega = -scale * sin(theta + 0.5 * dt * k1_theta);
    double k3_theta = omega + 0.5 * dt * k2_omega;
    double k3_omega = -scale * sin(theta + 0.5 * dt * k2_theta);
    double k4_theta = omega + dt * k3_omega;
    double k4_omega = -scale * sin(theta + dt * k3_theta);
    double theta_next = theta + dt / 6.0 *
        (k1_theta + 2.0 * k2_theta + 2.0 * k3_theta + k4_theta);
    double omega_next = omega + dt / 6.0 *
        (k1_omega + 2.0 * k2_omega + 2.0 * k3_omega + k4_omega);

    if (output == null || capacity < 2) return -2;
    output[0] = theta_next;
    output[1] = omega_next;
    return 2;
}
