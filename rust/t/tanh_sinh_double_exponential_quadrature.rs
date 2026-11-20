//! Bounded Takahasi-Mori tanh-sinh quadrature on [-1,1].
const MAX_PARSEABLE_INPUT_LENGTH: usize = 3;
const PI: f64 = 3.14159265358979323846264338327950288;

fn exact_integer(value: f64, low: i32, high: i32) -> Option<i32> {
    if !value.is_finite() || value < low as f64 || value > high as f64 || value.trunc() != value {
        return None;
    }
    Some(value as i32)
}

fn integrate(function_id: i32, p: i32) -> f64 {
    let h = 1.0 / (1_i32 << p) as f64;
    let half_pi = PI / 2.0;
    let limit = 3 * (1_i32 << p);
    let mut total = 0.0;
    for j in -limit..=limit {
        let t = j as f64 * h;
        let exp_t = t.exp();
        let exp_minus_t = (-t).exp();
        let sinh_t = (exp_t - exp_minus_t) * 0.5;
        let cosh_t = (exp_t + exp_minus_t) * 0.5;
        let u = half_pi * sinh_t;
        let abs_u = if u < 0.0 { -u } else { u };
        let q = (-2.0 * abs_u).exp();
        let one_plus_q = 1.0 + q;
        let sech_squared = (4.0 * q) / (one_plus_q * one_plus_q);
        let magnitude_x = (1.0 - q) / one_plus_q;
        let x = if u >= 0.0 { magnitude_x } else { -magnitude_x };
        let jacobian = (half_pi * cosh_t) * sech_squared;
        let sample = match function_id {
            0 => 1.0,
            1 => x * x,
            2 => 1.0 / sech_squared.sqrt(),
            _ if u >= 0.0 => 1.0 / ((2.0 * q) / one_plus_q).sqrt(),
            _ => 1.0 / (2.0 / one_plus_q).sqrt(),
        };
        let transformed = sample * jacobian;
        total += h * transformed;
    }
    total
}

#[no_mangle]
pub unsafe extern "C" fn tanh_sinh_double_exponential_quadrature(
    input: *const f64, input_length: usize, output: *mut f64, output_capacity: usize,
) -> i64 {
    if input.is_null() || !(2..=MAX_PARSEABLE_INPUT_LENGTH).contains(&input_length) { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, input_length) };
    if input_length != 2 { return -1; }
    let Some(function_id) = exact_integer(values[0], 0, 3) else { return -1; };
    let Some(p) = exact_integer(values[1], 2, 4) else { return -1; };
    if output.is_null() || output_capacity < 1 { return -2; }
    let value = integrate(function_id, p);
    if !value.is_finite() { return -1; }
    unsafe { *output = value; }
    1
}
