#[no_mangle]
pub unsafe extern "C" fn neville(values: *const i64, length: usize) -> f64 {
    const INVALID: f64 = -1.0e300;
    if values.is_null() || length < 4 || length > 34 { return INVALID; }
    let input = std::slice::from_raw_parts(values, length);
    let (count, target_i) = (input[0], input[1]);
    if !(1..=16).contains(&count) || length != (2 * count + 2) as usize || !(-1_000_000..=1_000_000).contains(&target_i) { return INVALID; }
    let n = count as usize;
    let mut x = [0.0_f64; 16];
    let mut p = [0.0_f64; 16];
    for i in 0..n {
        let (xi, yi) = (input[2 + 2 * i], input[3 + 2 * i]);
        if !(-1_000_000..=1_000_000).contains(&xi) || !(-1_000_000..=1_000_000).contains(&yi) || (0..i).any(|j| input[2 + 2 * j] == xi) { return INVALID; }
        x[i] = xi as f64; p[i] = yi as f64;
    }
    let target = target_i as f64;
    for k in 1..n { for i in 0..n-k { p[i] = ((target-x[i+k])*p[i] + (x[i]-target)*p[i+1])/(x[i]-x[i+k]); } }
    p[0]
}
