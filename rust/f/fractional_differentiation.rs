const INVALID: f64 = -1.0e300;
#[no_mangle]
pub unsafe extern "C" fn fractional_differentiation(values: *const i64, length: usize) -> f64 {
    if values.is_null() || !(4..=18).contains(&length) { return INVALID; }
    let x = std::slice::from_raw_parts(values, length);
    let (d_units, w) = (x[0], x[1]); let n = length - 2;
    if !(0..=1_000_000).contains(&d_units) || !(1..=8).contains(&w) || n <= w as usize || n > 16 { return INVALID; }
    if x[2..].iter().any(|v| *v < -1_000_000 || *v > 1_000_000) { return INVALID; }
    let d = d_units as f64 / 1_000_000.0; let mut weights = [0.0; 8]; weights[0] = 1.0;
    for k in 1..w as usize { weights[k] = -weights[k-1] * (d - k as f64 + 1.0) / k as f64; }
    let mut result = 0.0; for j in 0..w as usize { result += weights[j] * (x[2+n-1-j] as f64 / 1000.0); }
    result
}
