const INVALID_RESULT: f64 = -1.0e300;

#[no_mangle]
pub unsafe extern "C" fn schur_complement(input: *const i64, length: usize) -> f64 {
    if input.is_null() || length != 6 {
        return INVALID_RESULT;
    }
    let values = std::slice::from_raw_parts(input, length);
    let (a00, a01, a11) = (values[0], values[1], values[2]);
    let (b0, b1, c00) = (values[3], values[4], values[5]);
    if !(-8..=8).contains(&a00) || !(-8..=8).contains(&a01) || !(-8..=8).contains(&a11)
        || !(-100..=100).contains(&b0) || !(-100..=100).contains(&b1)
        || !(-100..=100).contains(&c00)
    {
        return INVALID_RESULT;
    }
    let determinant = a00 * a11 - a01 * a01;
    if determinant == 0 {
        return INVALID_RESULT;
    }
    let inv00 = a11 as f64 / determinant as f64;
    let inv01 = -(a01 as f64) / determinant as f64;
    let inv10 = -(a01 as f64) / determinant as f64;
    let inv11 = a00 as f64 / determinant as f64;
    let left0 = b0 as f64 * inv00 + b1 as f64 * inv10;
    let left1 = b0 as f64 * inv01 + b1 as f64 * inv11;
    let quadratic = left0 * b0 as f64 + left1 * b1 as f64;
    c00 as f64 - quadratic
}
