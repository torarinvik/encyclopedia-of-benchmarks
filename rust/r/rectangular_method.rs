const INVALID_RESULT: f64 = -1.0e300;

fn integrand(x: f64) -> f64 {
    (x.exp() / 2.0) * (x.cos() - x.sin())
}

#[no_mangle]
pub unsafe extern "C" fn rectangular_method(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length != 4 { return INVALID_RESULT; }
    let input = std::slice::from_raw_parts(values, length);
    let a_quarters = input[0];
    let b_quarters = input[1];
    let intervals = input[2];
    let rule = input[3];
    if a_quarters < -64 || a_quarters >= b_quarters || b_quarters > 64 ||
        !(1..=64).contains(&intervals) ||
        (b_quarters - a_quarters) % intervals != 0 ||
        (rule != 0 && rule != 1) { return INVALID_RESULT; }

    let a = a_quarters as f64 / 4.0;
    let b = b_quarters as f64 / 4.0;
    let step = (b - a) / intervals as f64;
    let mut x = a;
    let mut total = 0.0;
    for _ in 0..intervals {
        if rule == 0 {
            total += integrand(x) * step;
            x += step;
        } else {
            x += step;
            total += integrand(x) * step;
        }
    }
    total
}
