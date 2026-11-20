fn exact_integer(value: f64, low: i64, high: i64) -> Option<usize> {
    if !value.is_finite() || value < low as f64 || value > high as f64 || value.trunc() != value {
        return None;
    }
    Some(value as usize)
}

#[no_mangle]
pub unsafe extern "C" fn lanczos_symmetric_tridiagonalization(
    input: *const f64, input_length: usize, output: *mut f64, output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length < 3 || input_length > 19 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, input_length) };
    if values.iter().any(|value| !value.is_finite()) { return -1; }
    let Some(n) = exact_integer(values[0], 1, 4) else { return -1; };
    let Some(k) = exact_integer(values[1], 1, n as i64) else { return -1; };
    if input_length != 2 + n * n { return -1; }
    for row in 0..n {
        for col in 0..n {
            if exact_integer(values[2 + row * n + col], -4, 4).is_none()
                || values[2 + row * n + col] != values[2 + col * n + row] { return -1; }
        }
    }
    let required = 2 * k;
    if output.is_null() || output_capacity < required { return -2; }
    let mut previous = [0.0f64; 4];
    let mut current = [0.0f64; 4];
    let mut product = [0.0f64; 4];
    let mut residual = [0.0f64; 4];
    let mut next = [0.0f64; 4];
    let mut diagonal = [0.0f64; 4];
    let mut off_diagonal = [0.0f64; 3];
    current[0] = 1.0;
    let mut previous_beta = 0.0;
    for step in 0..k {
        for row in 0..n {
            product[row] = 0.0;
            for col in 0..n { product[row] += values[2 + row * n + col] * current[col]; }
        }
        let mut alpha = 0.0;
        for index in 0..n { alpha += current[index] * product[index]; }
        if !alpha.is_finite() { return -3; }
        diagonal[step] = alpha;
        if step + 1 == k { break; }
        let mut norm_squared = 0.0;
        for index in 0..n {
            residual[index] = product[index] - alpha * current[index] - previous_beta * previous[index];
            norm_squared += residual[index] * residual[index];
        }
        if !norm_squared.is_finite() || norm_squared < 0.0 { return -3; }
        let beta = norm_squared.sqrt();
        if !beta.is_finite() || beta <= 9.094947017729282e-13 { return -3; }
        off_diagonal[step] = beta;
        for index in 0..n { next[index] = residual[index] / beta; }
        for index in 0..n { previous[index] = current[index]; }
        for index in 0..n { current[index] = next[index]; }
        previous_beta = beta;
    }
    let out = unsafe { std::slice::from_raw_parts_mut(output, required) };
    out[0] = k as f64;
    for index in 0..k { out[1 + index] = diagonal[index]; }
    for index in 0..k - 1 { out[1 + k + index] = off_diagonal[index]; }
    required as i64
}
