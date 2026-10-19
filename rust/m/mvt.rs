const MAX_DIMENSION: usize = 64;
const MAX_CELLS: usize = MAX_DIMENSION * MAX_DIMENSION;
const INVALID_RESULT: f64 = -1e300;

#[no_mangle]
pub extern "C" fn mvt(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length != 1 { return INVALID_RESULT; }
    let raw_n = unsafe { *values };
    if raw_n < 1 || raw_n > MAX_DIMENSION as i64 { return INVALID_RESULT; }
    let n = raw_n as usize;
    let mut x1 = [0.0f64; MAX_DIMENSION];
    let mut x2 = [0.0f64; MAX_DIMENSION];
    let mut y1 = [0.0f64; MAX_DIMENSION];
    let mut y2 = [0.0f64; MAX_DIMENSION];
    let mut matrix = [0.0f64; MAX_CELLS];
    for i in 0..n {
        x1[i] = (i % n) as f64 / n as f64;
        x2[i] = ((i + 1) % n) as f64 / n as f64;
        y1[i] = ((i + 3) % n) as f64 / n as f64;
        y2[i] = ((i + 4) % n) as f64 / n as f64;
        for j in 0..n { matrix[i * n + j] = ((i * j) % n) as f64 / n as f64; }
    }
    for i in 0..n { for j in 0..n { x1[i] = x1[i] + matrix[i * n + j] * y1[j]; }}
    for i in 0..n { for j in 0..n { x2[i] = x2[i] + matrix[j * n + i] * y2[j]; }}
    let mut checksum = 0.0f64;
    for i in 0..n { checksum += x1[i]; }
    for i in 0..n { checksum += x2[i]; }
    checksum
}
