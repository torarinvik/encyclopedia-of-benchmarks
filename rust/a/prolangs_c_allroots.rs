use std::ffi::c_void;

const REQUIRED_BYTES: usize = 24;
const NEWTON_EPSILON: f64 = 5.0e-6;
const MAX_NEWTON_ITERATIONS: usize = 40;

fn absolute_value(value: f64) -> f64 { if value < 0.0 { -value } else { value } }

fn horner_value_and_derivative(coefficients: &[f64], x: f64) -> (f64, f64) {
    let degree = coefficients.len() - 1;
    let mut value = coefficients[degree];
    let mut slope = value;
    for j in (1..degree).rev() {
        value = x * value + coefficients[j];
        slope = x * slope + value;
    }
    value = x * value + coefficients[0];
    (value, slope)
}

fn newton_root(coefficients: &[f64], mut lower: f64, mut upper: f64) -> f64 {
    if upper < lower { std::mem::swap(&mut lower, &mut upper); }
    let mut previous = lower;
    let mut current = (lower + upper) / 2.0;
    let mut iterations = 0usize;
    while absolute_value(current - previous) / absolute_value(current) > NEWTON_EPSILON &&
          iterations <= MAX_NEWTON_ITERATIONS {
        previous = current;
        let (value, derivative) = horner_value_and_derivative(coefficients, current);
        current -= value / derivative;
        iterations += 1;
    }
    current
}

fn store_f64_le(value: f64, output: &mut [u8], offset: usize) {
    output[offset..offset + 8].copy_from_slice(&value.to_bits().to_le_bytes());
}

fn solve(staged: &mut [u8; REQUIRED_BYTES]) {
    let original = [4.0, -4.0, -1.0, 1.0];
    let mut coefficients = original;
    let upper = coefficients.iter().map(|value| absolute_value(*value)).sum::<f64>() /
                absolute_value(coefficients[3]);
    let lower = -upper - 1.0;

    let first_root = newton_root(&coefficients, lower, upper);
    let mut deflated = [0.0; 3];
    deflated[2] = coefficients[3];
    for i in (0..=1).rev() { deflated[i] = deflated[i + 1] * first_root + coefficients[i + 1]; }

    let discriminant = deflated[1] * deflated[1] - 4.0 * deflated[2] * deflated[0];
    let plus_root = (-deflated[1] + discriminant.sqrt()) / (2.0 * deflated[2]);
    let minus_root = (-deflated[1] - discriminant.sqrt()) / (2.0 * deflated[2]);
    let refined_plus = newton_root(&original, plus_root - 0.5, plus_root + 0.5);
    let refined_minus = newton_root(&original, minus_root - 0.5, minus_root + 0.5);
    store_f64_le(first_root, staged, 0);
    store_f64_le(refined_plus, staged, 8);
    store_f64_le(refined_minus, staged, 16);
}

#[no_mangle]
pub unsafe extern "C" fn prolangs_c_allroots(
    values: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if values.is_null() || length != 4 { return -1; }
    if *values != 4 || *values.add(1) != -4 || *values.add(2) != -1 || *values.add(3) != 1 {
        return -1;
    }
    if output.is_null() || output_capacity < REQUIRED_BYTES { return -2; }
    let mut staged = [0u8; REQUIRED_BYTES];
    solve(&mut staged);
    std::ptr::copy_nonoverlapping(staged.as_ptr(), output, REQUIRED_BYTES);
    REQUIRED_BYTES as i64
}
