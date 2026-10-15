/// Compute the Euclidean distance with the pinned Java coordinate expression.
#[no_mangle]
pub extern "C" fn distance_formula(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length != 4 { return -1.0e300; }
    let input = unsafe { std::slice::from_raw_parts(values, length) };
    if input.iter().any(|&value| !(-1_000_000..=1_000_000).contains(&value)) { return -1.0e300; }
    let dx = (input[2] - input[0]) as f64;
    let dy = (input[3] - input[0]) as f64;
    (dx * dx + dy * dy).sqrt()
}
