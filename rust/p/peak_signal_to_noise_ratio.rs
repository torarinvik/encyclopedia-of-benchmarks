use std::slice;

#[no_mangle]
pub extern "C" fn peak_signal_to_noise_ratio(v: *const i64, n: usize) -> f64 {
    if v.is_null() || n < 3 || n > 129 { return -1e300; }
    let values = unsafe { slice::from_raw_parts(v, n) };
    if !(1..=64).contains(&values[0]) || n != 1 + 2 * values[0] as usize { return -1e300; }
    let count = values[0] as usize;
    let mut sum = 0.0f64;
    for i in 0..count {
        let a = values[i + 1]; let b = values[i + 1 + count];
        if !(0..=255).contains(&a) || !(0..=255).contains(&b) { return -1e300; }
        if (a - b).abs() > 15 { return -1e300; }
        let d = a as f64 - b as f64; sum += d * d;
    }
    let mse = sum / count as f64;
    if mse == 0.0 { return -1e300; }
    20.0 * (255.0 / mse.sqrt()).log10()
}
