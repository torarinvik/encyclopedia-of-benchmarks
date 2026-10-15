fn absolute(value: f64) -> f64 {
    if value < 0.0 { -value } else { value }
}

#[no_mangle]
pub extern "C" fn babylonian_sqrt(input: f64) -> f64 {
    if !(input >= 0.0 && input <= 1_000_000.0) { return -1.0; }
    let mut estimate = input / 2.0;
    let tolerance = 0.000001;
    while tolerance <= absolute(estimate * estimate - input) {
        estimate = 0.5 * (estimate + input / estimate);
    }
    estimate
}
