#[no_mangle]
pub extern "C" fn exponential_function(power: f64, term_count: f64) -> f64 {
    if !(power >= -10.0 && power <= 10.0 && term_count >= 0.0 && term_count <= 32.0) { return -1.0e300; }
    let n = term_count as i32;
    if f64::from(n) != term_count { return -1.0e300; }
    if n == 0 { return 1.0; }

    let mut output = 0.0;
    let mut factorial = 1.0;
    for i in 0..n {
        output += power.powi(i) / factorial;
        factorial *= f64::from(i + 1);
    }
    output
}
