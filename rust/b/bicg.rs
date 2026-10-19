const MAX_DIMENSION: usize = 64;
const MAX_CELLS: usize = MAX_DIMENSION * MAX_DIMENSION;
const INVALID_RESULT: f64 = -1e300;

#[no_mangle]
pub extern "C" fn bicg(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length != 2 { return INVALID_RESULT; }
    let input = unsafe { std::slice::from_raw_parts(values, length) };
    if input[0] < 1 || input[0] > MAX_DIMENSION as i64 || input[1] < 1 || input[1] > MAX_DIMENSION as i64 {
        return INVALID_RESULT;
    }
    let (m, n) = (input[0] as usize, input[1] as usize);
    let mut matrix = [0.0f64; MAX_CELLS];
    let mut p = [0.0f64; MAX_DIMENSION];
    let mut r = [0.0f64; MAX_DIMENSION];
    let mut s = [0.0f64; MAX_DIMENSION];
    let mut q = [0.0f64; MAX_DIMENSION];
    for i in 0..m { p[i] = (i % m) as f64 / m as f64; }
    for i in 0..n {
        r[i] = (i % n) as f64 / n as f64;
        for j in 0..m { matrix[i * m + j] = (i * (j + 1) % n) as f64 / n as f64; }
    }
    for i in 0..m { s[i] = 0.0; }
    for i in 0..n {
        q[i] = 0.0;
        for j in 0..m {
            s[j] = s[j] + r[i] * matrix[i * m + j];
            q[i] = q[i] + matrix[i * m + j] * p[j];
        }
    }
    let mut checksum = 0.0f64;
    for j in 0..m { checksum += s[j]; }
    for i in 0..n { checksum += q[i]; }
    checksum
}
