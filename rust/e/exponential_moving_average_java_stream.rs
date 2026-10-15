#[no_mangle]
pub unsafe extern "C" fn exponential_moving_average_java_stream(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if !(0..=256).contains(&values[1]) || length != 2 + values[1] as usize || !(-1_000_000..=1_000_000).contains(&values[0]) { return -1; }
    let mut mean = values[0] as f64; let mut variance = 0.0_f64;
    for &sample in &values[2..] {
        if !(-1_000_000..=1_000_000).contains(&sample) { return -1; }
        let value = sample as f64;
        let deviation = value - mean;
        mean += 0.25 * deviation;
        variance = 0.75 * (variance + 0.25 * deviation * deviation);
    }
    if output.is_null() || capacity < 24 { return -2; }
    let bytes = std::slice::from_raw_parts_mut(output, 24);
    for (offset, value) in [(0_usize, mean), (8_usize, variance)] {
        let bits = value.to_bits();
        for byte in 0..8_usize { bytes[offset + byte] = (bits >> (8 * byte)) as u8; }
    }
    for byte in 0..8_usize { bytes[16 + byte] = (values[1] as u64 >> (8 * byte)) as u8; }
    24
}
