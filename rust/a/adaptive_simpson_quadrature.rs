const MAX_INPUT_LENGTH: usize = 6;

fn sample(function_id: i64, x: f64) -> f64 {
    match function_id {
        0 => x * x * x * x,
        1 => x.sin(),
        _ => 1.0 / (1.0 + x * x),
    }
}

fn simpson(a: f64, b: f64, fa: f64, fm: f64, fb: f64) -> f64 {
    (b - a) * (fa + 4.0 * fm + fb) / 6.0
}

fn refine(function_id: i64, a: f64, b: f64, fa: f64, fm: f64, fb: f64,
          whole: f64, tolerance: f64, depth: i64) -> f64 {
    let middle = (a + b) * 0.5;
    let left_middle = (a + middle) * 0.5;
    let right_middle = (middle + b) * 0.5;
    let flm = sample(function_id, left_middle);
    let frm = sample(function_id, right_middle);
    let left = simpson(a, middle, fa, flm, fm);
    let right = simpson(middle, b, fm, frm, fb);
    let delta = left + right - whole;
    if depth == 0 || delta.abs() <= 15.0 * tolerance {
        return left + right + delta / 15.0;
    }
    refine(function_id, a, middle, fa, flm, fm, left, tolerance * 0.5, depth - 1)
        + refine(function_id, middle, b, fm, frm, fb, right, tolerance * 0.5, depth - 1)
}

fn exact_integer(x: f64, low: i64, high: i64) -> bool {
    x.is_finite() && x >= low as f64 && x <= high as f64 && x.trunc() == x
}

#[no_mangle]
pub unsafe extern "C" fn adaptive_simpson_quadrature(
    input: *const f64, input_length: usize, output: *mut f64, output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length != 5 || input_length > MAX_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, input_length);
    if !exact_integer(values[0], 0, 2)
        || !exact_integer(values[1], -2_000_000, 2_000_000)
        || !exact_integer(values[2], -2_000_000, 2_000_000)
        || !exact_integer(values[3], 7, 8)
        || !exact_integer(values[4], 8, 12) { return -1; }
    let function_id = values[0] as i64;
    let a_micro = values[1] as i64;
    let b_micro = values[2] as i64;
    let exponent = values[3] as i64;
    let depth = values[4] as i64;
    if a_micro > b_micro { return -1; }
    if output.is_null() || output_capacity < 1 { return -2; }
    let a = a_micro as f64 / 1_000_000.0;
    let b = b_micro as f64 / 1_000_000.0;
    let mut answer = 0.0;
    if a != b {
        let middle = (a + b) * 0.5;
        let mut tolerance = 1.0;
        for _ in 0..exponent { tolerance *= 0.1; }
        let fa = sample(function_id, a);
        let fm = sample(function_id, middle);
        let fb = sample(function_id, b);
        answer = refine(function_id, a, b, fa, fm, fb,
                        simpson(a, b, fa, fm, fb), tolerance, depth);
    }
    if !answer.is_finite() { return -1; }
    output.write(answer);
    1
}
