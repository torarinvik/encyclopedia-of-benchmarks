/// Newton square root using binary64 arithmetic and a portable initial estimate.
#[no_mangle]
pub extern "C" fn square_root(value: f64) -> f64 {
    if value == 0.0 { return 0.0; }
    let mut estimate = if value >= 1.0 { value } else { 1.0 };
    for _ in 0..1100 {
        let next = 0.5 * estimate + 0.5 * (value / estimate);
        if next >= estimate { return estimate; }
        estimate = next;
    }
    estimate
}
