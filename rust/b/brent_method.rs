const INVALID_RESULT: f64 = -1.0e300;
const TOLERANCE: f64 = 1.0e-8;

fn function_value(function_id: i32, x: f64) -> f64 {
    match function_id {
        0 => x * x * x - x - 2.0,
        1 => x * x + 1.0,
        _ => x * x - 4.0 * x + 3.0,
    }
}

#[no_mangle]
pub extern "C" fn brent_method(function_id_value: f64, input_left: f64, input_right: f64) -> f64 {
    if function_id_value != 0.0 && function_id_value != 1.0 && function_id_value != 2.0 ||
        !(-4.0..=4.0).contains(&input_left) || !(-4.0..=4.0).contains(&input_right) || input_left >= input_right
    {
        return INVALID_RESULT;
    }
    let function_id = function_id_value as i32;
    let mut left = input_left;
    let mut right = input_right;
    let mut f_left = function_value(function_id, left);
    let mut f_right = function_value(function_id, right);
    if f_left * f_right >= 0.0 { return INVALID_RESULT; }
    if f_left.abs() < f_right.abs() {
        std::mem::swap(&mut left, &mut right);
        std::mem::swap(&mut f_left, &mut f_right);
    }

    let mut c = left;
    let mut f_c = f_left;
    let mut d = right - left;
    for iteration in 0..100 {
        if f_right == 0.0 { return right; }
        let mut candidate;
        if f_c != f_left && f_c != f_right {
            candidate = left * f_right * f_c / ((f_left - f_right) * (f_left - f_c)) +
                right * f_left * f_c / ((f_right - f_left) * (f_right - f_c)) +
                c * f_left * f_right / ((f_c - f_left) * (f_c - f_right));
        } else {
            candidate = right - f_right * (right - left) / (f_right - f_left);
        }

        let quarter = (3.0 * left + right) / 4.0;
        let outside = if right > left { !(quarter < candidate && candidate < right) }
                      else { !(right < candidate && candidate < quarter) };
        let use_bisection = outside ||
            (iteration > 1 && (candidate - right).abs() >= (right - c).abs() / 2.0) ||
            (iteration <= 1 && (candidate - right).abs() >= (c - d).abs() / 2.0) ||
            (iteration > 1 && (right - c).abs() < TOLERANCE) ||
            (iteration <= 1 && (c - d).abs() < TOLERANCE);
        if use_bisection {
            candidate = (left + right) / 2.0;
            d = right - left;
        }

        let f_candidate = function_value(function_id, candidate);
        d = c;
        c = right;
        f_c = f_right;
        if f_left * f_candidate < 0.0 {
            right = candidate;
            f_right = f_candidate;
        } else {
            left = candidate;
            f_left = f_candidate;
        }
        if f_left.abs() < f_right.abs() {
            std::mem::swap(&mut left, &mut right);
            std::mem::swap(&mut f_left, &mut f_right);
        }
        if (right - left).abs() < TOLERANCE { return right; }
    }
    right
}
