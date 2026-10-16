/// Interquartile range using the source lower/upper-half median rule.
fn median_i64(values: &[i64]) -> f64 {
    let middle = values.len() / 2;
    if values.len() % 2 != 0 { return values[middle] as f64; }
    (values[middle - 1] as f64 + values[middle] as f64) / 2.0
}

#[no_mangle]
pub unsafe extern "C" fn interquartile_range(values: *const i64, length: usize) -> f64 {
    if values.is_null() || !(2..=64).contains(&length) { return -1.0e300; }
    let input = unsafe { std::slice::from_raw_parts(values, length) };
    if input.iter().any(|&value| !(-1_000_000..=1_000_000).contains(&value)) { return -1.0e300; }
    let mut sorted = [0_i64; 64];
    sorted[..length].copy_from_slice(input);
    sorted[..length].sort_unstable();
    let half = length / 2;
    let upper_start = half + length % 2;
    let q1 = median_i64(&sorted[..half]);
    let q3 = median_i64(&sorted[upper_start..length]);
    q3 - q1
}
