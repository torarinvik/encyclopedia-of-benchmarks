const MAX_DIMENSION: usize = 64;
const MAX_CELLS: usize = MAX_DIMENSION * MAX_DIMENSION;
const INVALID_RESULT: f64 = -1e300;

#[no_mangle]
pub extern "C" fn covariance(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length != 2 { return INVALID_RESULT; }
    let input = unsafe { std::slice::from_raw_parts(values, length) };
    if input[0] < 2 || input[0] > MAX_DIMENSION as i64 || input[1] < 1 || input[1] > MAX_DIMENSION as i64 {
        return INVALID_RESULT;
    }
    let (n, m) = (input[0] as usize, input[1] as usize);
    let float_n = n as f64;
    let mut data = [0.0f64; MAX_CELLS];
    let mut cov = [0.0f64; MAX_CELLS];
    let mut mean = [0.0f64; MAX_DIMENSION];
    for i in 0..n {
        for j in 0..m { data[i * m + j] = (i as f64 * j as f64) / m as f64; }
    }
    for j in 0..m {
        mean[j] = 0.0;
        for i in 0..n { mean[j] += data[i * m + j]; }
        mean[j] /= float_n;
    }
    for i in 0..n {
        for j in 0..m { data[i * m + j] -= mean[j]; }
    }
    for i in 0..m {
        for j in i..m {
            cov[i * m + j] = 0.0;
            for k in 0..n { cov[i * m + j] += data[k * m + i] * data[k * m + j]; }
            cov[i * m + j] /= float_n - 1.0;
            cov[j * m + i] = cov[i * m + j];
        }
    }
    let mut checksum = 0.0f64;
    for i in 0..m {
        for j in 0..m { checksum += cov[i * m + j]; }
    }
    checksum
}
