const MAX_DIMENSION: usize = 64;
const MAX_CELLS: usize = MAX_DIMENSION * MAX_DIMENSION;
const INVALID_RESULT: f64 = -1e300;

#[no_mangle]
pub extern "C" fn gemm(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length != 3 { return INVALID_RESULT; }
    let input = unsafe { std::slice::from_raw_parts(values, length) };
    if input.iter().any(|&value| value < 1 || value > MAX_DIMENSION as i64) { return INVALID_RESULT; }
    let (ni, nj, nk) = (input[0] as usize, input[1] as usize, input[2] as usize);
    let (alpha, beta) = (1.5, 1.2);
    let mut c = [0.0f64; MAX_CELLS];
    let mut a = [0.0f64; MAX_CELLS];
    let mut b = [0.0f64; MAX_CELLS];
    for i in 0..ni {
        for j in 0..nj { c[i * nj + j] = ((i * j + 1) % ni) as f64 / ni as f64; }
    }
    for i in 0..ni {
        for k in 0..nk { a[i * nk + k] = (i * (k + 1) % nk) as f64 / nk as f64; }
    }
    for k in 0..nk {
        for j in 0..nj { b[k * nj + j] = (k * (j + 2) % nj) as f64 / nj as f64; }
    }
    for i in 0..ni {
        for j in 0..nj { c[i * nj + j] *= beta; }
        for k in 0..nk {
            for j in 0..nj { c[i * nj + j] += alpha * a[i * nk + k] * b[k * nj + j]; }
        }
    }
    let mut checksum = 0.0f64;
    for i in 0..ni {
        for j in 0..nj { checksum += c[i * nj + j]; }
    }
    checksum
}
