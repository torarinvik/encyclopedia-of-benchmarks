#[no_mangle]
pub extern "C" fn babylonian_method(input: f64) -> f64 {
    if !(input >= 2.0 && input <= 999_999.0) { return -1.0; }
    let radicand = input as i64;
    if radicand as f64 != input { return -1.0; }
    let mut i = 1_i64;
    while i * i <= radicand { i += 1; }
    i -= 1;
    if i * i == radicand { return -1.0; }
    let x0 = i as f64;
    (input / x0 + x0) / 2.0
}
