const MAX_N: i64 = 8;
const MAX_P: i64 = 6;
const INVALID_RESULT: f64 = -1.0e300;

#[no_mangle]
pub unsafe extern "C" fn minkowski_distance(packed: *const i64, length: usize) -> f64 {
    if packed.is_null() || length < 2 || length > 18 {
        return INVALID_RESULT;
    }
    let packed = std::slice::from_raw_parts(packed, length);
    let n = packed[0];
    let p = packed[1];
    if n < 0 || n > MAX_N || p < 3 || p > MAX_P || length != (2 + 2 * n) as usize {
        return INVALID_RESULT;
    }
    for index in 0..n as usize {
        if packed[2 + index] < -100 || packed[2 + index] > 100 ||
            packed[2 + n as usize + index] < -100 || packed[2 + n as usize + index] > 100 {
            return INVALID_RESULT;
        }
    }
    let mut total = 0i64;
    for index in 0..n as usize {
        let mut difference = packed[2 + index] - packed[2 + n as usize + index];
        if difference < 0 {
            difference = -difference;
        }
        let mut term = 1i64;
        for _ in 0..p {
            term *= difference;
        }
        total += term;
    }
    (total as f64).powf(1.0 / p as f64)
}
