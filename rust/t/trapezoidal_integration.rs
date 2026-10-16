const SCALE: i64 = 1_000_000;
const MAX_ENDPOINT_MICRO: i64 = 1_000_000;
const MAX_STEPS: i64 = 10_000;
const INVALID_RESULT: f64 = -1.0e300;

fn sample_value(function_id: i64, x: f64) -> f64 {
    if function_id == 0 { x * x } else { x * x * x }
}

#[no_mangle]
pub unsafe extern "C" fn trapezoidal_integration(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length != 4 { return INVALID_RESULT; }
    let start_micro = *values;
    let end_micro = *values.add(1);
    let steps = *values.add(2);
    let function_id = *values.add(3);
    if start_micro < -MAX_ENDPOINT_MICRO || start_micro > MAX_ENDPOINT_MICRO ||
        end_micro < -MAX_ENDPOINT_MICRO || end_micro > MAX_ENDPOINT_MICRO ||
        steps < 1 || steps > MAX_STEPS || function_id < 0 || function_id > 1 { return INVALID_RESULT; }

    let start = start_micro as f64 / SCALE as f64;
    let end = end_micro as f64 / SCALE as f64;
    let delta = (end - start) / steps as f64;
    let mut total = 0.0;
    for index in 0..steps {
        let left = start + delta * index as f64;
        let right = left + delta;
        let midpoint = f64::midpoint(sample_value(function_id, left), sample_value(function_id, right));
        total += midpoint * delta;
    }
    total
}
