// PolyBench/C trmm kernel, bounded port. Ohio State Software Distribution License: see benchmarks/t/trmm/LICENSE.txt.

const MAX_M: usize = 8;
const MAX_N: usize = 8;

#[no_mangle]
pub unsafe extern "C" fn trmm(input: *const f64, length: usize,
    output: *mut f64, capacity: usize) -> i64 {
    if input.is_null() || length != 2 { return -1; }
    let m_value = *input;
    let n_value = *input.add(1);
    if !m_value.is_finite() || !n_value.is_finite() || m_value.fract() != 0.0 || n_value.fract() != 0.0 ||
        m_value < 1.0 || m_value > MAX_M as f64 || n_value < 1.0 || n_value > MAX_N as f64 { return -1; }
    let m = m_value as usize;
    let n = n_value as usize;
    let required = m*n;
    if output.is_null() || capacity < required { return -2; }
    let mut a = [[0.0f64; MAX_M]; MAX_M];
    let mut b = [[0.0f64; MAX_N]; MAX_M];
    for i in 0..m {
        for j in 0..i { a[i][j] = ((i+j)%m) as f64 / m as f64; }
        a[i][i] = 1.0;
        for j in 0..n { b[i][j] = ((n+i-j)%n) as f64 / n as f64; }
    }
    for i in 0..m { for j in 0..n {
        for k in i+1..m { b[i][j] += a[k][i] * b[k][j]; }
        b[i][j] *= 1.5;
    }}
    let mut staged = [0.0f64; MAX_M*MAX_N];
    for i in 0..m { for j in 0..n { staged[i*n+j] = b[i][j]; }}
    std::ptr::copy_nonoverlapping(staged.as_ptr(), output, required);
    required as i64
}
