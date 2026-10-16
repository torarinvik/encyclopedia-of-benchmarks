const INVALID_RESULT: f64 = -1.0e300;

fn equation(x: f64) -> f64 { x.powf(3.0) - (4.0 * x) - 9.0 }
fn derivative(x: f64) -> f64 { 3.0 * x.powf(2.0) - 4.0 }

#[no_mangle]
pub unsafe extern "C" fn newton_raphson_method(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length != 2 { return INVALID_RESULT; }
    let input = std::slice::from_raw_parts(values, length);
    let initial_milli = input[0];
    let iteration_limit = input[1];
    if !(2000..=4000).contains(&initial_milli) || !(1..=32).contains(&iteration_limit) {
        return INVALID_RESULT;
    }
    let mut c = initial_milli as f64 / 1000.0;
    let mut z = c;
    for _ in 0..iteration_limit {
        let m = equation(c);
        let n = derivative(c);
        z = c - (m / n);
        c = z;
        if m.abs() < 1e-10 { break; }
    }
    z
}
