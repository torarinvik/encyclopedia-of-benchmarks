const MAX_DIMENSION: usize = 64;
const MAX_CELLS: usize = MAX_DIMENSION * MAX_DIMENSION;
const INVALID_RESULT: f64 = -1e300;

#[no_mangle]
pub extern "C" fn gemver(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length != 1 { return INVALID_RESULT; }
    let input = unsafe { std::slice::from_raw_parts(values, length) };
    if input[0] < 1 || input[0] > MAX_DIMENSION as i64 { return INVALID_RESULT; }
    let n = input[0] as usize;
    let (alpha, beta) = (1.5, 1.2);
    let fn64 = n as f64;
    let mut a = [0.0f64; MAX_CELLS];
    let (mut u1, mut v1, mut u2, mut v2) = ([0.0f64; MAX_DIMENSION], [0.0f64; MAX_DIMENSION], [0.0f64; MAX_DIMENSION], [0.0f64; MAX_DIMENSION]);
    let (mut w, mut x, mut y, mut z) = ([0.0f64; MAX_DIMENSION], [0.0f64; MAX_DIMENSION], [0.0f64; MAX_DIMENSION], [0.0f64; MAX_DIMENSION]);
    for i in 0..n {
        u1[i] = i as f64;
        u2[i] = ((i as f64 + 1.0) / fn64) / 2.0;
        v1[i] = ((i as f64 + 1.0) / fn64) / 4.0;
        v2[i] = ((i as f64 + 1.0) / fn64) / 6.0;
        y[i] = ((i as f64 + 1.0) / fn64) / 8.0;
        z[i] = ((i as f64 + 1.0) / fn64) / 9.0;
        for j in 0..n { a[i * n + j] = ((i * j) % n) as f64 / fn64; }
    }
    for i in 0..n {
        for j in 0..n { a[i * n + j] = a[i * n + j] + u1[i] * v1[j] + u2[i] * v2[j]; }
    }
    for i in 0..n {
        for j in 0..n { x[i] = x[i] + beta * a[j * n + i] * y[j]; }
    }
    for i in 0..n { x[i] = x[i] + z[i]; }
    for i in 0..n {
        for j in 0..n { w[i] = w[i] + alpha * a[i * n + j] * x[j]; }
    }
    let mut checksum = 0.0f64;
    for i in 0..n { checksum += w[i]; }
    checksum
}
