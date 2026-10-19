const MAX_DIMENSION: usize = 16;
const MAX_CELLS: usize = MAX_DIMENSION * MAX_DIMENSION;
const INVALID_RESULT: f64 = -1e300;

#[no_mangle]
pub extern "C" fn three_mm(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length != 5 { return INVALID_RESULT; }
    let input = unsafe { std::slice::from_raw_parts(values, length) };
    if input.iter().any(|&value| value < 1 || value > MAX_DIMENSION as i64) { return INVALID_RESULT; }
    let (ni, nj, nk, nl, nm) = (input[0] as usize, input[1] as usize, input[2] as usize, input[3] as usize, input[4] as usize);
    let mut a = [0.0f64; MAX_CELLS];
    let mut b = [0.0f64; MAX_CELLS];
    let mut c = [0.0f64; MAX_CELLS];
    let mut d = [0.0f64; MAX_CELLS];
    let mut e = [0.0f64; MAX_CELLS];
    let mut f = [0.0f64; MAX_CELLS];
    let mut g = [0.0f64; MAX_CELLS];
    for i in 0..ni {
        for k in 0..nk { a[i * nk + k] = ((i * k + 1) % ni) as f64 / (5 * ni) as f64; }
    }
    for k in 0..nk {
        for j in 0..nj { b[k * nj + j] = ((k * (j + 1) + 2) % nj) as f64 / (5 * nj) as f64; }
    }
    for i in 0..nj {
        for j in 0..nm { c[i * nm + j] = (i * (j + 3) % nl) as f64 / (5 * nl) as f64; }
    }
    for i in 0..nm {
        for j in 0..nl { d[i * nl + j] = ((i * (j + 2) + 2) % nk) as f64 / (5 * nk) as f64; }
    }
    for i in 0..ni {
        for j in 0..nj {
            e[i * nj + j] = 0.0;
            for k in 0..nk { e[i * nj + j] += a[i * nk + k] * b[k * nj + j]; }
        }
    }
    for i in 0..nj {
        for j in 0..nl {
            f[i * nl + j] = 0.0;
            for k in 0..nm { f[i * nl + j] += c[i * nm + k] * d[k * nl + j]; }
        }
    }
    for i in 0..ni {
        for j in 0..nl {
            g[i * nl + j] = 0.0;
            for k in 0..nj { g[i * nl + j] += e[i * nj + k] * f[k * nl + j]; }
        }
    }
    let mut checksum = 0.0f64;
    for i in 0..ni {
        for j in 0..nl { checksum += g[i * nl + j]; }
    }
    checksum
}
