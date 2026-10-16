#[no_mangle]
pub unsafe extern "C" fn verlet(
    values: *const f64,
    length: usize,
    output: *mut f64,
    capacity: usize,
) -> i64 {
    if values.is_null() || length != 4 { return -1; }
    let v = std::slice::from_raw_parts(values, length);
    if v.iter().any(|value| !value.is_finite()) ||
        !(2.0..=32.0).contains(&v[0]) || v[0].fract() != 0.0 ||
        !(-1.0..=1.0).contains(&v[1]) || !(-1.0..=1.0).contains(&v[2]) ||
        !(0.0..=4.0).contains(&v[3]) || v[3].fract() != 0.0 {
        return -1;
    }

    let n = v[0] as usize;
    let code = v[3] as usize;
    let dt = match code {
        0 => 0.00390625,
        1 => 0.0078125,
        2 => 0.015625,
        3 => 0.03125,
        _ => 0.0625,
    };
    let dt_squared = dt * dt;
    if output.is_null() || capacity < 2 * n { return -2; }

    *output = v[1];
    *output.add(1) = v[1] + v[2] * dt + 0.5 * (-v[1]) * dt_squared;
    for i in 1..n - 1 {
        *output.add(i + 1) = 2.0 * *output.add(i) - *output.add(i - 1)
            + (-*output.add(i)) * dt_squared;
    }
    for i in 0..n {
        *output.add(n + i) = (i as f64) * dt;
    }
    (2 * n) as i64
}
