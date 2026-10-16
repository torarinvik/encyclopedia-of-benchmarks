fn put_f64_le(output: &mut [u8], offset: usize, value: f64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn damped_oscillator(input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length != 5 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if values[0] < 1 || values[0] > 1024 || values[1] < 0 || values[1] > 1024 ||
        !(-1024..=1024).contains(&values[2]) || !(-1024..=1024).contains(&values[3]) ||
        values[4] < 1 || values[4] > 1024 { return -1; }
    if output.is_null() || capacity < 16 { return -2; }
    let omega0 = values[0] as f64 / 1024.0;
    let gamma = values[1] as f64 / 1024.0;
    let x = values[2] as f64 / 1024.0;
    let v = values[3] as f64 / 1024.0;
    let dt = values[4] as f64 / 1024.0;
    let acceleration = -2.0 * gamma * v - omega0 * omega0 * x;
    let x_next = x + dt * v;
    let v_next = v + dt * acceleration;
    let result = std::slice::from_raw_parts_mut(output, 16);
    put_f64_le(result, 0, x_next);
    put_f64_le(result, 8, v_next);
    16
}
