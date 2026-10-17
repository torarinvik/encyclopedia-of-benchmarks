const INVALID_RESULT: f64 = -1.0e300;
const MAX_ENDPOINT_MICRO: i64 = 10_000_000;

fn integrand(x: f64) -> f64 {
    (-x).exp() * (4.0 - x.powf(2.0))
}

#[no_mangle]
pub unsafe extern "C" fn simpson_integration(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length != 3 { return INVALID_RESULT; }
    let input = std::slice::from_raw_parts(values, length);
    let intervals = input[0];
    let a_micro = input[1];
    let b_micro = input[2];
    if !(2..=128).contains(&intervals) || intervals % 2 != 0 ||
        !(-MAX_ENDPOINT_MICRO..=MAX_ENDPOINT_MICRO).contains(&a_micro) ||
        !(-MAX_ENDPOINT_MICRO..=MAX_ENDPOINT_MICRO).contains(&b_micro) || a_micro > b_micro {
        return INVALID_RESULT;
    }
    let a = a_micro as f64 / 1_000_000.0;
    let b = b_micro as f64 / 1_000_000.0;
    if a == b { return 0.0; }
    let h = (b - a) / intervals as f64;
    let mut xi = a;
    let mut total = 0.0;
    for index in 0..=intervals {
        let sample = integrand(xi);
        if index == 0 || index == intervals { total += sample; }
        else if index % 2 != 0 { total += 4.0 * sample; }
        else { total += 2.0 * sample; }
        xi += h;
    }
    (h / 3.0) * total
}
