#[no_mangle]
pub unsafe extern "C" fn rayleigh_quotient(
    values: *const f64,
    length: usize,
    output: *mut f64,
    capacity: usize,
) -> i64 {
    if values.is_null() || length == 0 || length > 273 {
        return -1;
    }
    let values = std::slice::from_raw_parts(values, length);
    if values.iter().any(|value| !value.is_finite()) {
        return -1;
    }
    let n_value = values[0];
    if !(1.0..=16.0).contains(&n_value) || n_value.fract() != 0.0 {
        return -1;
    }
    let n = n_value as usize;
    if length != 1 + n * n + n {
        return -1;
    }
    let matrix_start = 1;
    let vector_start = 1 + n * n;

    for row in 0..n {
        for col in 0..n {
            let value = values[matrix_start + row * n + col];
            if !(-1000.0..=1000.0).contains(&value) {
                return -1;
            }
            if col > row && value != values[matrix_start + col * n + row] {
                return -1;
            }
        }
    }

    let mut denominator = 0.0;
    for i in 0..n {
        let value = values[vector_start + i];
        if !(-100.0..=100.0).contains(&value) {
            return -1;
        }
        denominator += value * value;
    }
    if denominator <= 0.0 {
        return -1;
    }

    let mut numerator = 0.0;
    for col in 0..n {
        let mut v_star_dot = 0.0;
        for row in 0..n {
            v_star_dot += values[vector_start + row] * values[matrix_start + row * n + col];
        }
        numerator += v_star_dot * values[vector_start + col];
    }
    let quotient = numerator / denominator;
    if output.is_null() || capacity < 1 {
        return -2;
    }
    *output = quotient;
    1
}
