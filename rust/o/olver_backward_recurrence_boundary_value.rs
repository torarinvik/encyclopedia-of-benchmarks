//! Bounded Olver cutoff and backward recurrence over binary64 coefficients.

const MAX_PARSEABLE_INPUT_LENGTH: usize = 53;

fn exact_integer(value: f64, low: i32, high: i32) -> Option<i32> {
    if !value.is_finite() || value < low as f64 || value > high as f64 || value.trunc() != value {
        return None;
    }
    Some(value as i32)
}

fn valid(values: &[f64]) -> Option<(usize, usize)> {
    if !(8..=MAX_PARSEABLE_INPUT_LENGTH).contains(&values.len()) || values.iter().any(|x| !x.is_finite()) {
        return None;
    }
    let m = exact_integer(values[0], 1, 8)? as usize;
    let nmax = exact_integer(values[1], 1, 12)? as usize;
    if m > nmax || values.len() != 4 + 4 * nmax || values[2] < 2.0f64.powi(-40)
        || values[2] > 0.5 || values[3].abs() > 16.0 { return None; }
    for i in 0..nmax {
        if values[4 + i].abs() < 0.0625 || values[4 + i].abs() > 16.0
            || values[4 + nmax + i].abs() > 16.0
            || values[4 + 2 * nmax + i].abs() > 16.0
            || values[4 + 3 * nmax + i].abs() > 16.0 { return None; }
    }
    Some((m, nmax))
}

#[no_mangle]
pub unsafe extern "C" fn olver_backward_recurrence_boundary_value(
    input: *const f64, input_length: usize, output: *mut f64, output_capacity: usize,
) -> i64 {
    if input.is_null() || !(8..=MAX_PARSEABLE_INPUT_LENGTH).contains(&input_length) { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, input_length) };
    let Some((m, nmax)) = valid(values) else { return -1; };
    let required = m + 2;
    if output.is_null() || output_capacity < required { return -2; }
    let mut p = [0.0f64; 14];
    let mut e = [0.0f64; 13];
    let mut w = [0.0f64; 13];
    p[1] = 1.0;
    e[0] = values[3];
    for n in 1..=m {
        let a = values[4 + n - 1];
        let b = values[4 + nmax + n - 1];
        let c = values[4 + 2 * nmax + n - 1];
        let d = values[4 + 3 * nmax + n - 1];
        p[n + 1] = (b * p[n] - c * p[n - 1]) / a;
        e[n] = (c * e[n - 1] - d * p[n]) / a;
        if !p[n + 1].is_finite() || !e[n].is_finite() { return -3; }
    }
    for n in 1..=m {
        let product = p[n] * p[n + 1];
        if product == 0.0 || !product.is_finite() || !(e[n] / product).is_finite() { return -3; }
    }
    let mut minimum = f64::INFINITY;
    for n in 1..=m { minimum = minimum.min((e[n] / (p[n] * p[n + 1])).abs()); }
    let threshold = values[2] * minimum;
    let mut endpoint = 0usize;
    for n in m..=nmax {
        if n > m {
            let a = values[4 + n - 1];
            let b = values[4 + nmax + n - 1];
            let c = values[4 + 2 * nmax + n - 1];
            let d = values[4 + 3 * nmax + n - 1];
            p[n + 1] = (b * p[n] - c * p[n - 1]) / a;
            e[n] = (c * e[n - 1] - d * p[n]) / a;
            if !p[n + 1].is_finite() || !e[n].is_finite() { return -3; }
        }
        let product = p[n] * p[n + 1];
        if product == 0.0 || !product.is_finite() { return -3; }
        let ratio = (e[n] / product).abs();
        if !ratio.is_finite() { return -3; }
        if ratio <= threshold { endpoint = n; break; }
    }
    if endpoint == 0 { return -3; }
    for n in (0..endpoint).rev() {
        w[n] = (p[n] * w[n + 1] + e[n]) / p[n + 1];
        if !w[n].is_finite() { return -3; }
    }
    let out = unsafe { std::slice::from_raw_parts_mut(output, required) };
    out[0] = endpoint as f64;
    out[1..].copy_from_slice(&w[..=m]);
    required as i64
}
