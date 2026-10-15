#[no_mangle]
pub unsafe extern "C" fn euler_method(input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length != 4 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if !(-8..=8).contains(&values[0]) || !(-8..=8).contains(&values[1]) || !(1..=4).contains(&values[2]) || !(1..=16).contains(&values[3]) { return -1; }
    let steps = values[3] as usize; let required = 8 * (steps + 1);
    if output.is_null() || capacity < required { return -2; }
    let h = 1.0_f64 / (1_i64 << values[2]) as f64;
    let mut x = values[0] as f64; let mut y = values[1] as f64;
    let bytes = std::slice::from_raw_parts_mut(output, required);
    for step in 0..=steps {
        let bits = y.to_bits();
        for byte in 0..8_usize { bytes[step * 8 + byte] = (bits >> (byte * 8)) as u8; }
        if step < steps { y = y + h * (x + y); x += h; }
    }
    required as i64
}
