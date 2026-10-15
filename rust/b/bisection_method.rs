/// Find a root of one of two documented cubics by interval bisection.
const MAX_COORD_MILLI: i64 = 100_000;
const MAX_TOLERANCE_MICRO: i64 = 1_000_000;
const ROOT_SCALE: f64 = 1_000_000.0;
const MAX_ITERATIONS: usize = 64;

fn evaluate(equation: i64, x: f64) -> f64 {
    if equation == 0 { x * x * x + 2.0 * x - 10.0 }
    else { x * x * x - 4.0 * x - 9.0 }
}

#[no_mangle]
pub unsafe extern "C" fn bisection_method(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length != 4 { return -1; }
    let equation = *input;
    let left_milli = *input.add(1);
    let right_milli = *input.add(2);
    let tolerance_micro = *input.add(3);
    if !(0..=1).contains(&equation) || !(-MAX_COORD_MILLI..=MAX_COORD_MILLI).contains(&left_milli) ||
        !(-MAX_COORD_MILLI..=MAX_COORD_MILLI).contains(&right_milli) || left_milli >= right_milli ||
        !(1..=MAX_TOLERANCE_MICRO).contains(&tolerance_micro) { return -1; }
    let mut left = left_milli as f64 / 1000.0;
    let mut right = right_milli as f64 / 1000.0;
    let mut f_left = evaluate(equation, left);
    let f_right = evaluate(equation, right);
    if f_left == 0.0 { return (left * ROOT_SCALE + 0.5) as i64; }
    if f_right == 0.0 { return (right * ROOT_SCALE + 0.5) as i64; }
    if (f_left < 0.0) == (f_right < 0.0) { return -2; }
    let tolerance = tolerance_micro as f64 / ROOT_SCALE;
    for _ in 0..MAX_ITERATIONS {
        let middle = left + (right - left) * 0.5;
        let f_middle = evaluate(equation, middle);
        if f_middle == 0.0 { return (middle * ROOT_SCALE + 0.5) as i64; }
        if (f_left < 0.0) != (f_middle < 0.0) { right = middle; }
        else { left = middle; f_left = f_middle; }
        if right - left <= tolerance {
            return ((left + (right - left) * 0.5) * ROOT_SCALE + 0.5) as i64;
        }
    }
    -2
}
