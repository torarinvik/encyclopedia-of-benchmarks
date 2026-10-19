const MAX_DIMENSION: usize = 64;
const MAX_CELLS: usize = MAX_DIMENSION * MAX_DIMENSION;
const INVALID_RESULT: f64 = -1e300;

#[no_mangle]
pub extern "C" fn polybench_cholesky(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length != 1 { return INVALID_RESULT; }
    let input = unsafe { std::slice::from_raw_parts(values, length) };
    if input[0] < 1 || input[0] > MAX_DIMENSION as i64 { return INVALID_RESULT; }
    let n = input[0] as usize;
    let mut a = [0.0f64; MAX_CELLS];
    let mut product = [0.0f64; MAX_CELLS];
    for i in 0..n {
        for j in 0..=i { a[i * n + j] = (-(j as i64 % n as i64)) as f64 / n as f64 + 1.0; }
        for j in i + 1..n { a[i * n + j] = 0.0; }
        a[i * n + i] = 1.0;
    }
    for t in 0..n {
        for r in 0..n {
            for s in 0..n {
                product[r * n + s] = product[r * n + s] + a[r * n + t] * a[s * n + t];
            }
        }
    }
    for r in 0..n { for s in 0..n { a[r * n + s] = product[r * n + s]; } }
    for i in 0..n {
        for j in 0..i {
            for k in 0..j { a[i * n + j] = a[i * n + j] - a[i * n + k] * a[j * n + k]; }
            a[i * n + j] = a[i * n + j] / a[j * n + j];
        }
        for k in 0..i { a[i * n + i] = a[i * n + i] - a[i * n + k] * a[i * n + k]; }
        a[i * n + i] = a[i * n + i].sqrt();
    }
    let mut result = 0.0;
    for i in 0..n { for j in 0..=i { result += a[i * n + j]; } }
    result
}
