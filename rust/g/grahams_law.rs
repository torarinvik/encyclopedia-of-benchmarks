fn rounded_six(value: f64) -> f64 {
    if !(0.0..=1.0e6).contains(&value) { return -1.0e300; }
    let scaled = value * 1_000_000.0;
    let mut lower = scaled.floor();
    let fraction = scaled - lower;
    if fraction >= 0.499 && fraction <= 0.501 { return -1.0e300; }
    if fraction > 0.5 { lower += 1.0; }
    lower / 1_000_000.0
}

fn decode_positive(values: &[i64], index: usize) -> f64 {
    let result = f64::from_bits(values[index] as u64);
    if result.is_finite() && (1.0e-6..=1.0e6).contains(&result) { result } else { 0.0 }
}

#[no_mangle]
pub unsafe extern "C" fn grahams_law(values: *const i64, length: usize) -> f64 {
    if values.is_null() || !(3..=4).contains(&length) { return -1.0e300; }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    let operation = values[0];
    if !(0..=4).contains(&operation) || (operation == 0 && length != 3) || (operation != 0 && length != 4) {
        return -1.0e300;
    }
    let first = decode_positive(values, 1);
    let second = decode_positive(values, 2);
    if first == 0.0 || second == 0.0 { return -1.0e300; }
    let result = match operation {
        0 => (second / first).sqrt(),
        1 => { let third = decode_positive(values, 3); if third == 0.0 { return -1.0e300; } first * (third / second).sqrt() },
        2 => { let third = decode_positive(values, 3); if third == 0.0 { return -1.0e300; } first / (third / second).sqrt() },
        3 => { let third = decode_positive(values, 3); if third == 0.0 { return -1.0e300; } first / (second / third).powf(2.0) },
        _ => { let third = decode_positive(values, 3); if third == 0.0 { return -1.0e300; } (second / third).powf(2.0) / first },
    };
    if result.is_finite() { rounded_six(result) } else { -1.0e300 }
}
