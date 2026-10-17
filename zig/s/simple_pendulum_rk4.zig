const std = @import("std");

export fn simple_pendulum_rk4(values: [*c]const f64, length: usize,
    output: [*c]f64, capacity: usize) i64 {
    if (values == null or length != 5) return -1;
    const minimums = [_]f64{ 10000.0, 100000.0, -3141593.0, -100000000.0, 1.0 };
    const maximums = [_]f64{ 100000000.0, 20000000.0, 3141593.0, 100000000.0, 100000.0 };
    for (0..5) |i| {
        if (!std.math.isFinite(values[i]) or @floor(values[i]) != values[i] or
            values[i] < minimums[i] or values[i] > maximums[i]) return -1;
    }

    const length_m = values[0] / 1000000.0;
    const gravity = values[1] / 1000000.0;
    const theta = values[2] / 1000000.0;
    const omega = values[3] / 1000000.0;
    const dt = values[4] / 1000000.0;
    const scale = gravity / length_m;

    const k1_theta = omega;
    const k1_omega = -scale * @sin(theta);
    const k2_theta = omega + 0.5 * dt * k1_omega;
    const k2_omega = -scale * @sin(theta + 0.5 * dt * k1_theta);
    const k3_theta = omega + 0.5 * dt * k2_omega;
    const k3_omega = -scale * @sin(theta + 0.5 * dt * k2_theta);
    const k4_theta = omega + dt * k3_omega;
    const k4_omega = -scale * @sin(theta + dt * k3_theta);
    const theta_next = theta + dt / 6.0 *
        (k1_theta + 2.0 * k2_theta + 2.0 * k3_theta + k4_theta);
    const omega_next = omega + dt / 6.0 *
        (k1_omega + 2.0 * k2_omega + 2.0 * k3_omega + k4_omega);

    if (output == null or capacity < 2) return -2;
    output[0] = theta_next;
    output[1] = omega_next;
    return 2;
}
