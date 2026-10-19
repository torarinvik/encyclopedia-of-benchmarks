const MAX_DIMENSION: usize = 64;
const MAX_CELLS: usize = MAX_DIMENSION * MAX_DIMENSION;
const INVALID_RESULT: f64 = -1e300;

#[no_mangle]
pub extern "C" fn atax(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length != 2 { return INVALID_RESULT; }
    let input = unsafe { std::slice::from_raw_parts(values, length) };
    if input[0] < 1 || input[0] > MAX_DIMENSION as i64 || input[1] < 1 || input[1] > MAX_DIMENSION as i64 {
        return INVALID_RESULT;
    }
    let (m, n) = (input[0] as usize, input[1] as usize);
    let mut matrix = [0.0f64; MAX_CELLS];
    let mut x = [0.0f64; MAX_DIMENSION];
    let mut y = [0.0f64; MAX_DIMENSION];
    let mut temporary = [0.0f64; MAX_DIMENSION];
    let fn_value = n as f64;
    for i in 0..n { x[i] = 1.0 + i as f64 / fn_value; }
    for i in 0..m { for j in 0..n {
        matrix[i * n + j] = ((i + j) % n) as f64 / (5 * m) as f64;
    }}
    for i in 0..n { y[i] = 0.0; }
    for i in 0..m {
        temporary[i] = 0.0;
        for j in 0..n { temporary[i] = temporary[i] + matrix[i * n + j] * x[j]; }
        for j in 0..n { y[j] = y[j] + matrix[i * n + j] * temporary[i]; }
    }
    let mut checksum = 0.0f64;
    for j in 0..n { checksum += y[j]; }
    checksum
}
