#[no_mangle]
pub unsafe extern "C" fn simple_pendulum_rk4(
    values: *const f64,
    length: usize,
    output: *mut f64,
    capacity: usize,
) -> i64 {
    if values.is_null() || length != 5 {
        return -1;
    }
    let values = std::slice::from_raw_parts(values, length);
    let minimums = [10_000.0, 100_000.0, -3_141_593.0, -100_000_000.0, 1.0];
    let maximums = [100_000_000.0, 20_000_000.0, 3_141_593.0, 100_000_000.0, 100_000.0];
    for index in 0..5 {
        let value = values[index];
        if !value.is_finite() || value.trunc() != value ||
            value < minimums[index] || value > maximums[index] {
            return -1;
        }
    }

    let length_m = values[0] / 1_000_000.0;
    let gravity = values[1] / 1_000_000.0;
    let theta = values[2] / 1_000_000.0;
    let omega = values[3] / 1_000_000.0;
    let dt = values[4] / 1_000_000.0;
    let scale = gravity / length_m;

    let k1_theta = omega;
    let k1_omega = -scale * theta.sin();
    let k2_theta = omega + 0.5 * dt * k1_omega;
    let k2_omega = -scale * (theta + 0.5 * dt * k1_theta).sin();
    let k3_theta = omega + 0.5 * dt * k2_omega;
    let k3_omega = -scale * (theta + 0.5 * dt * k2_theta).sin();
    let k4_theta = omega + dt * k3_omega;
    let k4_omega = -scale * (theta + dt * k3_theta).sin();
    let theta_next = theta + dt / 6.0 *
        (k1_theta + 2.0 * k2_theta + 2.0 * k3_theta + k4_theta);
    let omega_next = omega + dt / 6.0 *
        (k1_omega + 2.0 * k2_omega + 2.0 * k3_omega + k4_omega);

    if output.is_null() || capacity < 2 {
        return -2;
    }
    *output.add(0) = theta_next;
    *output.add(1) = omega_next;
    2
}
