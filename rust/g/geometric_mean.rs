const MAX_LENGTH: usize = 6;
const MAX_ABS_VALUE: i64 = 100;
const INVALID_RESULT: f64 = -1.0e300;

#[no_mangle]
pub unsafe extern "C" fn geometric_mean(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length == 0 || length > MAX_LENGTH {
        return INVALID_RESULT;
    }
    let values = std::slice::from_raw_parts(values, length);
    let mut product = 1i64;
    for &value in values {
        if !(-MAX_ABS_VALUE..=MAX_ABS_VALUE).contains(&value) {
            return INVALID_RESULT;
        }
        product *= value;
    }
    if product < 0 && length % 2 == 0 {
        return INVALID_RESULT;
    }
    let magnitude = if product < 0 { -product } else { product };
    let mut root = (magnitude as f64).powf(1.0 / length as f64);
    let rounded = (root + 0.5).floor();
    let mut rounded_power = 1i64;
    for _ in 0..length {
        rounded_power *= rounded as i64;
    }
    if (product >= 0 && rounded_power == product)
        || (product < 0 && length % 2 == 1 && -rounded_power == product)
    {
        root = rounded;
    }
    if product < 0 {
        root = -root;
    }
    root
}
