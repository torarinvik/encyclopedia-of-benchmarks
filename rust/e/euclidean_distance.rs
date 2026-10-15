const MAX_DIMENSION: i64 = 128;
const INVALID_RESULT: f64 = -1.0e300;

#[no_mangle]
pub extern "C" fn euclidean_distance(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length < 1 { return INVALID_RESULT; }
    let dimension = unsafe { *values };
    if dimension < 0 || dimension > MAX_DIMENSION
        || length != 1 + 2 * dimension as usize { return INVALID_RESULT; }
    let mut sum_of_squares = 0.0f64;
    for i in 0..dimension as usize {
        let first = unsafe { *values.add(1 + i) };
        let second = unsafe { *values.add(1 + dimension as usize + i) };
        if !(-1_000_000..=1_000_000).contains(&first)
            || !(-1_000_000..=1_000_000).contains(&second) { return INVALID_RESULT; }
        let difference = first as f64 - second as f64;
        sum_of_squares += difference * difference;
    }
    sum_of_squares.sqrt()
}
