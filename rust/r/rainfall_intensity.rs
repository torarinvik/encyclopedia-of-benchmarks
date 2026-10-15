/// Sherman rainfall intensity curve over bounded integer inputs.
#[no_mangle]
pub extern "C" fn rainfall_intensity(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length != 6 { return -1.0e300; }
    let k = unsafe { *values };
    let a = unsafe { *values.add(1) };
    let b = unsafe { *values.add(2) };
    let c = unsafe { *values.add(3) };
    let period = unsafe { *values.add(4) };
    let duration = unsafe { *values.add(5) };
    if !(1..=1000).contains(&k) || !(1..=3).contains(&a) || !(1..=100).contains(&b)
        || !(1..=3).contains(&c) || !(1..=100).contains(&period) || !(1..=1000).contains(&duration)
    { return -1.0e300; }
    (k as f64 * (period as f64).powf(a as f64)) / ((duration + b) as f64).powf(c as f64)
}
