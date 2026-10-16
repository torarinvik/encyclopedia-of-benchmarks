const MAX_INPUT: usize = 128;

fn put_f64_le(output: &mut [u8], offset: usize, value: f64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn dispersion(
    values: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if values.is_null() || length == 0 || length > MAX_INPUT { return -1; }
    let values = std::slice::from_raw_parts(values, length);
    if values.iter().any(|&value| !(-10000..=10000).contains(&value)) { return -1; }
    if output.is_null() || capacity < 16 { return -2; }
    let mut sum = 0.0f64;
    for &value in values { sum += value as f64; }
    let mean = sum / length as f64;
    let mut squared_deviations = 0.0f64;
    for &value in values {
        let deviation = value as f64 - mean;
        squared_deviations += deviation * deviation;
    }
    let variance = squared_deviations / length as f64;
    let standard_deviation = variance.sqrt();
    let output = std::slice::from_raw_parts_mut(output, 16);
    put_f64_le(output, 0, variance);
    put_f64_le(output, 8, standard_deviation);
    16
}
