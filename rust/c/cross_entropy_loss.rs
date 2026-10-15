/// Cross-entropy loss with source-ordered intermediate terms and summation.
#[no_mangle]
pub extern "C" fn cross_entropy_loss(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length < 1 { return -1.0e300; }
    let count = unsafe { *values };
    if !(1..=64).contains(&count) || length != 1 + 2 * count as usize { return -1.0e300; }
    let mut terms = Vec::with_capacity(count as usize);
    for i in 0..count as usize {
        let actual_scaled = unsafe { *values.add(1 + i) };
        let predicted_scaled = unsafe { *values.add(1 + count as usize + i) };
        if !(0..=1_000_000).contains(&actual_scaled)
            || !(1..=1_000_000).contains(&predicted_scaled)
        {
            return -1.0e300;
        }
        let actual = actual_scaled as f64 / 1_000_000.0;
        let predicted = predicted_scaled as f64 / 1_000_000.0;
        terms.push(-actual * predicted.ln());
    }
    terms.iter().sum()
}
