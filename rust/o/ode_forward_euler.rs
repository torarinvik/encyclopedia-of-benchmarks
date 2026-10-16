fn store_f64_le(output: &mut [u8], offset: usize, value: f64) {
    let bits = value.to_bits();
    for byte in 0..8 { output[offset + byte] = (bits >> (8 * byte)) as u8; }
}

#[no_mangle]
pub unsafe extern "C" fn ode_forward_euler(values: *const i64, length: usize,
        output: *mut u8, output_capacity: usize) -> i64 {
    if values.is_null() || length != 4 { return -1; }
    let input = std::slice::from_raw_parts(values, length);
    if !(1..=16).contains(&input[0]) || !(1..=4).contains(&input[1]) ||
        !(-10..=10).contains(&input[2]) || !(-10..=10).contains(&input[3]) { return -1; }
    if output.is_null() || output_capacity < 16 { return -2; }
    let dt = input[1] as f64 / 4.0;
    let mut u = input[2] as f64;
    let mut v = input[3] as f64;
    for _ in 0..input[0] {
        let old_u = u;
        let old_v = v;
        u = old_u + dt * old_v;
        v = old_v - dt * old_u;
    }
    let bytes = std::slice::from_raw_parts_mut(output, 16);
    store_f64_le(bytes, 0, u);
    store_f64_le(bytes, 8, v);
    16
}
