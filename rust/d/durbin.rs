const MAX_N: usize = 40;

#[no_mangle]
pub unsafe extern "C" fn durbin(input: *const f64, length: usize,
                                 output: *mut f64, capacity: usize) -> i64 {
    if input.is_null() || length != 1 { return -1; }
    let n_value = *input;
    if !n_value.is_finite() || n_value.fract() != 0.0 || n_value < 1.0 || n_value > MAX_N as f64 {
        return -1;
    }
    let n = n_value as usize;
    if output.is_null() || capacity < n { return -2; }

    let mut r = [0.0; MAX_N];
    let mut y = [0.0; MAX_N];
    let mut z = [0.0; MAX_N];
    for i in 0..n { r[i] = (n + 1 - i) as f64; }
    y[0] = -r[0];
    let mut beta = 1.0;
    let mut alpha = -r[0];
    for k in 1..n {
        beta = (1.0 - alpha * alpha) * beta;
        let mut sum = 0.0;
        for i in 0..k { sum += r[k - i - 1] * y[i]; }
        alpha = -(r[k] + sum) / beta;
        for i in 0..k { z[i] = y[i] + alpha * y[k - i - 1]; }
        for i in 0..k { y[i] = z[i]; }
        y[k] = alpha;
    }
    std::ptr::copy_nonoverlapping(y.as_ptr(), output, n);
    n as i64
}
