const MAX_INPUT_LENGTH: usize = 6;

fn integer_field(value: f64, low: i64, high: i64) -> Option<i64> {
    if value.is_finite() && value >= low as f64 && value <= high as f64 && value.trunc() == value {
        Some(value as i64)
    } else { None }
}

fn polynomial(id: i64, x: f64) -> f64 {
    match id { 0 => x*x-2.0, 1 => x*x*x-2.0, 2 => x*x*x+x-1.0, _ => x }
}
fn opposite(a: f64, b: f64) -> bool { (a < 0.0) != (b < 0.0) }

fn solve(id: i64, mut left: f64, mut right: f64, tolerance: f64,
         iterations: i64) -> Result<f64, i64> {
    let mut f_left = polynomial(id, left);
    let mut f_right = polynomial(id, right);
    if f_left == 0.0 { return Ok(left); }
    if f_right == 0.0 { return Ok(right); }
    for _ in 0..iterations {
        if right-left <= tolerance { return Ok((left+right)*0.5); }
        let middle = (left+right)*0.5;
        let f_middle = polynomial(id, middle);
        if f_middle == 0.0 { return Ok(middle); }
        let radicand = f_middle*f_middle-f_left*f_right;
        if !radicand.is_finite() || radicand <= 0.0 { return Err(-3); }
        let denominator = radicand.sqrt();
        if !denominator.is_finite() || denominator == 0.0 { return Err(-3); }
        let direction = if f_left < f_right { -1.0 } else { 1.0 };
        let candidate = middle+(middle-left)*direction*f_middle/denominator;
        if !candidate.is_finite() || !(left < candidate && candidate < right) { return Err(-3); }
        let f_candidate = polynomial(id, candidate);
        if f_candidate == 0.0 { return Ok(candidate); }
        if opposite(f_left, f_candidate) { right = candidate; f_right = f_candidate; }
        else { left = candidate; f_left = f_candidate; }
        if right-left <= tolerance { return Ok((left+right)*0.5); }
    }
    Err(-3)
}

#[no_mangle]
pub unsafe extern "C" fn ridders_root_finding(
    input: *const f64, input_length: usize, output: *mut f64, output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length != 5 || input_length > MAX_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, input_length);
    let Some(id) = integer_field(values[0], 0, 3) else { return -1; };
    let Some(left_milli) = integer_field(values[1], -3000, 3000) else { return -1; };
    let Some(right_milli) = integer_field(values[2], -3000, 3000) else { return -1; };
    let Some(tolerance_micro) = integer_field(values[3], 1, 1000) else { return -1; };
    let Some(iterations) = integer_field(values[4], 24, 32) else { return -1; };
    if left_milli >= right_milli { return -1; }
    let left = left_milli as f64/1000.0;
    let right = right_milli as f64/1000.0;
    let f_left = polynomial(id, left);
    let f_right = polynomial(id, right);
    if f_left != 0.0 && f_right != 0.0 && !opposite(f_left, f_right) { return -1; }
    if output.is_null() || output_capacity < 1 { return -2; }
    let root = match solve(id, left, right, tolerance_micro as f64/1_000_000.0, iterations) {
        Ok(value) if value.is_finite() => value,
        Ok(_) => return -3,
        Err(status) => return status,
    };
    output.write(root);
    1
}
