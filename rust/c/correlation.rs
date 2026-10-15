const INVALID_RESULT: f64 = -1.0e300;
const DELTA: f64 = 1.0e-9;

#[no_mangle]
pub extern "C" fn correlation(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length < 3 { return INVALID_RESULT; }
    let n_value = unsafe { *values };
    if !(1..=128).contains(&n_value) || length != 1 + 2 * n_value as usize { return INVALID_RESULT; }
    let n = n_value as usize;
    let mut exy = 0.0;
    let mut ex = 0.0;
    let mut exx = 0.0;
    let mut ey = 0.0;
    let mut eyy = 0.0;
    for i in 0..n {
        let xi = unsafe { *values.add(1 + i) };
        let yi = unsafe { *values.add(1 + n + i) };
        if !(-1000..=1000).contains(&xi) || !(-1000..=1000).contains(&yi) { return INVALID_RESULT; }
        let x = xi as f64;
        let y = yi as f64;
        exy += x * y;
        ex += x;
        exx += x * x;
        ey += y;
        eyy += y * y;
    }
    exy /= n as f64;
    ex /= n as f64;
    exx /= n as f64;
    ey /= n as f64;
    eyy /= n as f64;
    let cov = exy - ex * ey;
    let varx = (exx - ex * ex).sqrt();
    let vary = (eyy - ey * ey).sqrt();
    if varx * vary < DELTA { return 0.0; }
    cov / (varx * vary).sqrt()
}
