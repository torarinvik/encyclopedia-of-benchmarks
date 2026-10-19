const MAX_DIMENSION: usize = 64;
const MAX_CELLS: usize = MAX_DIMENSION * MAX_DIMENSION;
const INVALID_RESULT: f64 = -1e300;

#[no_mangle]
pub extern "C" fn polybench_symm(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length != 2 { return INVALID_RESULT; }
    let input = unsafe { std::slice::from_raw_parts(values, length) };
    if input[0] < 1 || input[0] > MAX_DIMENSION as i64 || input[1] < 1 || input[1] > MAX_DIMENSION as i64 {
        return INVALID_RESULT;
    }
    let (m, n) = (input[0] as usize, input[1] as usize);
    let mut a = [0.0f64; MAX_CELLS];
    let mut b = [0.0f64; MAX_CELLS];
    let mut c = [0.0f64; MAX_CELLS];
    let (alpha, beta) = (1.5, 1.2);
    for i in 0..m {
        for j in 0..n {
            c[i * n + j] = ((i + j) % 100) as f64 / m as f64;
            b[i * n + j] = ((n + i - j) % 100) as f64 / m as f64;
        }
    }
    for i in 0..m {
        for j in 0..m {
            a[i * m + j] = if j <= i { ((i + j) % 100) as f64 / m as f64 } else { -999.0 };
        }
    }
    for i in 0..m {
        for j in 0..n {
            let mut temp2 = 0.0;
            for k in 0..i {
                c[k * n + j] = c[k * n + j] + alpha * b[i * n + j] * a[i * m + k];
                temp2 = temp2 + b[k * n + j] * a[i * m + k];
            }
            c[i * n + j] = beta * c[i * n + j] + alpha * b[i * n + j] * a[i * m + i] + alpha * temp2;
        }
    }
    let mut result = 0.0;
    for i in 0..m { for j in 0..n { result += c[i * n + j]; } }
    result
}
