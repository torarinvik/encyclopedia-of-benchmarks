const MAX_DIMENSION: usize = 64;
const MAX_CELLS: usize = MAX_DIMENSION * MAX_DIMENSION;
const INVALID_RESULT: f64 = -1e300;

#[no_mangle]
pub extern "C" fn polybench_ludcmp(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length != 1 { return INVALID_RESULT; }
    let input = unsafe { std::slice::from_raw_parts(values, length) };
    if input[0] < 1 || input[0] > MAX_DIMENSION as i64 { return INVALID_RESULT; }
    let n = input[0] as usize;
    let mut a = [0.0f64; MAX_CELLS];
    let mut product = [0.0f64; MAX_CELLS];
    let mut b = [0.0f64; MAX_DIMENSION];
    let mut x = [0.0f64; MAX_DIMENSION];
    let mut y = [0.0f64; MAX_DIMENSION];
    for i in 0..n {
        x[i] = 0.0;
        y[i] = 0.0;
        b[i] = (i as f64 + 1.0) / n as f64 / 2.0 + 4.0;
    }
    for i in 0..n {
        for j in 0..=i { a[i * n + j] = (-(j as i64 % n as i64)) as f64 / n as f64 + 1.0; }
        for j in i + 1..n { a[i * n + j] = 0.0; }
        a[i * n + i] = 1.0;
    }
    for r in 0..n { for s in 0..n { product[r * n + s] = 0.0; } }
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
            let mut w = a[i * n + j];
            for k in 0..j { w = w - a[i * n + k] * a[k * n + j]; }
            a[i * n + j] = w / a[j * n + j];
        }
        for j in i..n {
            let mut w = a[i * n + j];
            for k in 0..i { w = w - a[i * n + k] * a[k * n + j]; }
            a[i * n + j] = w;
        }
    }
    for i in 0..n {
        let mut w = b[i];
        for j in 0..i { w = w - a[i * n + j] * y[j]; }
        y[i] = w;
    }
    for i in (0..n).rev() {
        let mut w = y[i];
        for j in i + 1..n { w = w - a[i * n + j] * x[j]; }
        x[i] = w / a[i * n + i];
    }
    let mut result = 0.0;
    for i in 0..n { result += x[i]; }
    result
}
