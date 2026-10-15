const MAX_COORDINATE: i64 = 1_000_000;
const INVALID_RESULT: f64 = -1.0e300;

#[no_mangle]
pub unsafe extern "C" fn distance_between_two_points(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length != 4 {
        return INVALID_RESULT;
    }
    let values = std::slice::from_raw_parts(values, length);
    if values.iter().any(|&value| !(-MAX_COORDINATE..=MAX_COORDINATE).contains(&value)) {
        return INVALID_RESULT;
    }
    let dx = (values[2] - values[0]) as f64;
    let dy = (values[3] - values[1]) as f64;
    (dx * dx + dy * dy).sqrt()
}
