const MAX_DIMENSION: usize = 64;
const INVALID_RESULT: f64 = -1e300;

#[no_mangle]
pub extern "C" fn gesummv(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length != 1 { return INVALID_RESULT; }
    let input = unsafe { *values };
    if input < 1 || input > MAX_DIMENSION as i64 { return INVALID_RESULT; }
    let n = input as usize;
    let mut x = [0.0; MAX_DIMENSION];
    for i in 0..n { x[i] = (i % n) as f64 / n as f64; }
    let mut result = 0.0;
    for i in 0..n {
        let mut temporary = 0.0;
        let mut y = 0.0;
        for j in 0..n {
            let a = ((i * j + 1) % n) as f64 / n as f64;
            let b = ((i * j + 2) % n) as f64 / n as f64;
            temporary = a * x[j] + temporary;
            y = b * x[j] + y;
        }
        y = 1.5 * temporary + 1.2 * y;
        result += y;
    }
    result
}
