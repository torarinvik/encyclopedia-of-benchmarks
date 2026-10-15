const INVALID_RESULT: f64 = -1.0e300;
const MAX_ENDPOINT_MILLI: i64 = 100_000;

fn equation(x: f64) -> f64 { 10.0 - x * x }

#[no_mangle]
pub unsafe extern "C" fn bisection_2(input: *const i64, length: usize) -> f64 {
    if input.is_null() || length != 2 { return INVALID_RESULT; }
    let values = std::slice::from_raw_parts(input, length);
    let (left_milli, right_milli) = (values[0], values[1]);
    if left_milli < -MAX_ENDPOINT_MILLI || left_milli > MAX_ENDPOINT_MILLI
        || right_milli < -MAX_ENDPOINT_MILLI || right_milli > MAX_ENDPOINT_MILLI
        || left_milli >= right_milli { return INVALID_RESULT; }
    let mut a = left_milli as f64 / 1000.0;
    let mut b = right_milli as f64 / 1000.0;
    if equation(a) * equation(b) >= 0.0 { return INVALID_RESULT; }
    let mut c = a;
    while (b - a) >= 0.01 {
        c = (a + b) / 2.0;
        if equation(c) == 0.0 { break; }
        if equation(c) * equation(a) < 0.0 { b = c; }
        else { a = c; }
    }
    c
}
