const MAX_N: usize = 30;
const MAX_TSTEPS: usize = 20;

#[no_mangle]
pub unsafe extern "C" fn jacobi_2d(input: *const f64, length: usize,
                                     output: *mut f64, capacity: usize) -> i64 {
    if input.is_null() || length != 2 { return -1; }
    let n_value = *input;
    let steps_value = *input.add(1);
    if !n_value.is_finite() || !steps_value.is_finite() ||
        n_value.fract() != 0.0 || steps_value.fract() != 0.0 ||
        n_value < 1.0 || n_value > MAX_N as f64 ||
        steps_value < 0.0 || steps_value > MAX_TSTEPS as f64 { return -1; }
    let n = n_value as usize;
    let tsteps = steps_value as usize;
    let count = n * n;
    if output.is_null() || capacity < count { return -2; }

    let mut a = [[0.0; MAX_N]; MAX_N];
    let mut b = [[0.0; MAX_N]; MAX_N];
    for i in 0..n {
        for j in 0..n {
            a[i][j] = (i as f64 * (j + 2) as f64 + 2.0) / n as f64;
            b[i][j] = (i as f64 * (j + 3) as f64 + 3.0) / n as f64;
        }
    }
    for _ in 0..tsteps {
        if n > 2 {
            for i in 1..(n - 1) {
                for j in 1..(n - 1) {
                    b[i][j] = 0.2 * (a[i][j] + a[i][j - 1] + a[i][j + 1] + a[i + 1][j] + a[i - 1][j]);
                }
            }
            for i in 1..(n - 1) {
                for j in 1..(n - 1) {
                    a[i][j] = 0.2 * (b[i][j] + b[i][j - 1] + b[i][j + 1] + b[i + 1][j] + b[i - 1][j]);
                }
            }
        }
    }
    for i in 0..n { for j in 0..n { *output.add(i * n + j) = a[i][j]; } }
    count as i64
}
