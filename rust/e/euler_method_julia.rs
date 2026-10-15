#[no_mangle]
pub unsafe extern "C" fn euler_method_julia(input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length != 3 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if !(-8..=8).contains(&values[0]) || !(1..=16).contains(&values[1]) || !(1..=4).contains(&values[2]) { return -1; }
    let steps = values[1] as usize; let required = 16 * steps;
    if output.is_null() || capacity < required { return -2; }
    let h = 1.0_f64 / (1_i64 << values[2]) as f64;
    let mut states = [0.0_f64; 16]; let mut times = [0.0_f64; 16];
    states[0] = values[0] as f64;
    for i in 0..steps - 1 { states[i + 1] = states[i] + h * (states[i] + times[i]); times[i + 1] = times[i] + h; }
    let bytes = std::slice::from_raw_parts_mut(output, required);
    for i in 0..steps {
        for (offset, value) in [(8 * i, states[i]), (8 * (steps + i), times[i])] {
            let bits = value.to_bits(); for byte in 0..8_usize { bytes[offset + byte] = (bits >> (8 * byte)) as u8; }
        }
    }
    required as i64
}
