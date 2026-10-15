#[no_mangle]
pub extern "C" fn decimal_isolate(input: f64) -> f64 {
    if !(input > 0.0 && input <= 999_999.0) { return -1.0; }
    let scaled_value = input * 10_000.0;
    let scaled = scaled_value as i64;
    if scaled as f64 != scaled_value || scaled as f64 / 10_000.0 != input { return -1.0; }
    if scaled % 625 != 0 || scaled % 10_000 == 0 { return -1.0; }
    (scaled % 10_000) as f64 / 10_000.0
}
