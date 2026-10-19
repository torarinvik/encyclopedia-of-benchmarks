const MAX_N: usize = 40;

#[no_mangle]
pub unsafe extern "C" fn trisolv(input: *const f64, length: usize,
                                  output: *mut f64, capacity: usize) -> i64 {
    if input.is_null() || length != 1 { return -1; }
    let n_value = *input;
    if !n_value.is_finite() || n_value.fract() != 0.0 || n_value < 1.0 || n_value > MAX_N as f64 {
        return -1;
    }
    let n = n_value as usize;
    if output.is_null() || capacity < n { return -2; }

    let mut lower = [[0.0; MAX_N]; MAX_N];
    let mut b = [0.0; MAX_N];
    let mut x = [0.0; MAX_N];
    for i in 0..n {
        b[i] = i as f64;
        for j in 0..=i {
            lower[i][j] = (i + n - j + 1) as f64 * 2.0 / n as f64;
        }
    }
    for i in 0..n {
        x[i] = b[i];
        for j in 0..i { x[i] -= lower[i][j] * x[j]; }
        x[i] /= lower[i][i];
    }
    std::ptr::copy_nonoverlapping(x.as_ptr(), output, n);
    n as i64
}
