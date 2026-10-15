/// Return the n-dimensional Manhattan distance between two integer points.
#[no_mangle]
pub extern "C" fn manhattan_distance(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length < 3 { return -1.0e300; }
    let dimensions = unsafe { *values };
    if !(1..=16).contains(&dimensions) || length != 1 + 2 * dimensions as usize { return -1.0e300; }
    let mut total = 0_i64;
    for index in 0..dimensions as usize {
        let first = unsafe { *values.add(1 + index) };
        let second = unsafe { *values.add(1 + dimensions as usize + index) };
        if !(-1_000_000..=1_000_000).contains(&first) || !(-1_000_000..=1_000_000).contains(&second) {
            return -1.0e300;
        }
        total += (first - second).abs();
    }
    total as f64
}
