//! Bounded Clenshaw-Curtis quadrature on supplied Lobatto-node samples.
const MAX_PARSEABLE_INPUT_LENGTH: usize = 19;
const PI: f64 = 3.14159265358979323846264338327950288;

fn exact_integer(value: f64, low: i32, high: i32) -> Option<i32> {
    if !value.is_finite() || value < low as f64 || value > high as f64 || value.trunc() != value {
        return None;
    }
    Some(value as i32)
}

fn compute(n: i32, samples: &[f64]) -> f64 {
    let mut result = 0.0;
    for k in 0..=n {
        let mut inner = 0.0;
        for j in 1..=n / 2 {
            let bj = if j == n / 2 { 1.0 } else { 2.0 };
            let denominator = (4 * j * j - 1) as f64;
            let angle = (((2.0 * j as f64) * k as f64) * PI) / n as f64;
            let term = (bj / denominator) * angle.cos();
            inner += term;
        }
        let gk = if k == 0 || k == n { 1.0 } else { 2.0 };
        let weight = (gk / n as f64) * (1.0 - inner);
        result += weight * samples[k as usize];
    }
    result
}

#[no_mangle]
pub unsafe extern "C" fn clenshaw_curtis_quadrature(
    input: *const f64, input_length: usize, output: *mut f64, output_capacity: usize,
) -> i64 {
    if input.is_null() || !(4..=MAX_PARSEABLE_INPUT_LENGTH).contains(&input_length) { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, input_length) };
    let Some(n) = exact_integer(values[0], 2, 16) else { return -1; };
    if n % 2 != 0 || input_length != n as usize + 2
        || values[1..].iter().any(|x| !x.is_finite() || x.abs() > 1000.0) { return -1; }
    if output.is_null() || output_capacity < 1 { return -2; }
    let value = compute(n, &values[1..]);
    if !value.is_finite() { return -1; }
    unsafe { *output = value; }
    1
}
