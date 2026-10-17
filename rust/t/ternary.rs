const MAX_INPUT_LENGTH: usize = 6;
const INVALID_RESULT: f64 = -1.0e300;

fn objective(operation: i64, x: f64) -> f64 {
    let delta = if operation == 0 { x - 1.0 } else { x + 1.0 };
    let square = delta * delta;
    if operation == 0 { -square } else { square }
}

fn ternary_search(operation: i64, a: f64, b: f64, epsilon: f64,
                  frame: i64, max_calls: i64) -> f64 {
    if (a - b).abs() <= epsilon { return objective(operation, (a + b) / 2.0); }

    let left = (2.0 * a + b) / 3.0;
    let right = (a + 2.0 * b) / 3.0;
    let left_value = objective(operation, left);
    let right_value = objective(operation, right);
    let take_left = if operation == 0 { left_value < right_value } else { left_value > right_value };
    if frame >= max_calls { return INVALID_RESULT; }
    if take_left { return ternary_search(operation, left, b, epsilon, frame + 1, max_calls); }
    ternary_search(operation, a, right, epsilon, frame + 1, max_calls)
}

#[no_mangle]
pub unsafe extern "C" fn ternary(input: *const i64, length: usize) -> f64 {
    if input.is_null() || length < 5 || length > MAX_INPUT_LENGTH { return INVALID_RESULT; }
    let values = std::slice::from_raw_parts(input, length);
    let operation = values[0];
    let a_milli = values[1];
    let b_milli = values[2];
    let epsilon_micro = values[3];
    let max_calls = values[4];
    if length != 5 || (operation != 0 && operation != 1) ||
        a_milli < -1_000_000 || a_milli > b_milli || b_milli > 1_000_000 ||
        epsilon_micro < 1 || epsilon_micro > 1_000_000 || !(1..=64).contains(&max_calls) {
        return INVALID_RESULT;
    }

    ternary_search(operation, a_milli as f64 / 1000.0, b_milli as f64 / 1000.0,
                   epsilon_micro as f64 / 1_000_000.0, 1, max_calls)
}
