const MAX_DIMENSION: usize = 16;
const MAX_CELLS: usize = MAX_DIMENSION * MAX_DIMENSION;
const INVALID_RESULT: f64 = -1e300;

#[no_mangle]
pub extern "C" fn two_mm(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length != 4 { return INVALID_RESULT; }
    let input = unsafe { std::slice::from_raw_parts(values, length) };
    if input.iter().any(|&value| value < 1 || value > MAX_DIMENSION as i64) { return INVALID_RESULT; }
    let (ni, nj, nk, nl) = (input[0] as usize, input[1] as usize, input[2] as usize, input[3] as usize);
    let (alpha, beta) = (1.5, 1.2);
    let mut a = [0.0f64; MAX_CELLS];
    let mut b = [0.0f64; MAX_CELLS];
    let mut c = [0.0f64; MAX_CELLS];
    let mut d = [0.0f64; MAX_CELLS];
    let mut tmp = [0.0f64; MAX_CELLS];
    for i in 0..ni {
        for k in 0..nk { a[i * nk + k] = ((i * k + 1) % ni) as f64 / ni as f64; }
    }
    for k in 0..nk {
        for j in 0..nj { b[k * nj + j] = (k * (j + 1) % nj) as f64 / nj as f64; }
    }
    for j in 0..nj {
        for l in 0..nl { c[j * nl + l] = ((j * (l + 3) + 1) % nl) as f64 / nl as f64; }
    }
    for i in 0..ni {
        for l in 0..nl { d[i * nl + l] = (i * (l + 2) % nk) as f64 / nk as f64; }
    }
    for i in 0..ni {
        for j in 0..nj {
            tmp[i * nj + j] = 0.0;
            for k in 0..nk { tmp[i * nj + j] += alpha * a[i * nk + k] * b[k * nj + j]; }
        }
    }
    for i in 0..ni {
        for l in 0..nl {
            d[i * nl + l] *= beta;
            for j in 0..nj { d[i * nl + l] += tmp[i * nj + j] * c[j * nl + l]; }
        }
    }
    let mut checksum = 0.0f64;
    for i in 0..ni {
        for l in 0..nl { checksum += d[i * nl + l]; }
    }
    checksum
}
