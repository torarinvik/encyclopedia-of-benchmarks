const OUTPUT_LENGTH: usize = 4;

fn round_ties_to_even(value: f64) -> i64 {
    let lower = value.floor();
    let fraction = value - lower;
    let base = lower as i64;
    if fraction < 0.5 { return base; }
    if fraction > 0.5 { return base + 1; }
    if base % 2 == 0 { base } else { base + 1 }
}

#[no_mangle]
pub unsafe extern "C" fn rgb_cmyk_conversion(input: *const i64, length: usize,
                                               output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length != 3 { return -1; }
    let values = std::slice::from_raw_parts(input, 3);
    if values.iter().any(|&value| !(0..=255).contains(&value)) { return -1; }
    if output.is_null() || capacity < OUTPUT_LENGTH { return -2; }
    let out = std::slice::from_raw_parts_mut(output, OUTPUT_LENGTH);
    let red = values[0] as f64 / 255.0;
    let green = values[1] as f64 / 255.0;
    let blue = values[2] as f64 / 255.0;
    let maximum = red.max(green).max(blue);
    let key = 1.0 - maximum;
    if key == 1.0 { out.copy_from_slice(&[0, 0, 0, 100]); return OUTPUT_LENGTH as i64; }
    let denominator = 1.0 - key;
    out[0] = round_ties_to_even(100.0 * (1.0 - red - key) / denominator) as u8;
    out[1] = round_ties_to_even(100.0 * (1.0 - green - key) / denominator) as u8;
    out[2] = round_ties_to_even(100.0 * (1.0 - blue - key) / denominator) as u8;
    out[3] = round_ties_to_even(100.0 * key) as u8;
    OUTPUT_LENGTH as i64
}
