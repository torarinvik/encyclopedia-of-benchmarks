const MAX_N: usize = 8;
const MAX_M: usize = 16;

#[no_mangle]
pub extern "C" fn syr2k(
    input: *const f64,
    length: usize,
    output: *mut f64,
    capacity: usize,
) -> i64 {
    if input.is_null() || length != 2 { return -1; }
    let (n_value, m_value) = unsafe { (*input, *input.add(1)) };
    if !n_value.is_finite() || !m_value.is_finite()
        || n_value.fract() != 0.0 || m_value.fract() != 0.0
        || n_value < 1.0 || n_value > MAX_N as f64
        || m_value < 1.0 || m_value > MAX_M as f64 { return -1; }
    let n = n_value as usize;
    let m = m_value as usize;
    let alpha = 1.5;
    let beta = 1.2;
    let mut a = [0.0_f64; MAX_N * MAX_M];
    let mut b = [0.0_f64; MAX_N * MAX_M];
    let mut c = [0.0_f64; MAX_N * MAX_N];

    for i in 0..n {
        for j in 0..m {
            a[i * m + j] = ((i * j + 1) % n) as f64 / n as f64;
            b[i * m + j] = ((i * j + 2) % m) as f64 / m as f64;
        }
    }
    for i in 0..n {
        for j in 0..n {
            c[i * n + j] = ((i * j + 3) % n) as f64 / m as f64;
        }
    }

    for i in 0..n {
        for j in 0..=i { c[i * n + j] *= beta; }
        for k in 0..m {
            for j in 0..=i {
                c[i * n + j] += a[j * m + k] * alpha * b[i * m + k]
                              + b[j * m + k] * alpha * a[i * m + k];
            }
        }
    }

    let required = n * n;
    if output.is_null() || capacity < required { return -2; }
    for index in 0..required {
        unsafe { *output.add(index) = c[index]; }
    }
    required as i64
}
