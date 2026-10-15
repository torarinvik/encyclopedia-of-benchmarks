/// Inductive reactance relation over a bounded integer-valued domain.
#[no_mangle]
pub extern "C" fn ind_reactance(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length != 3 { return -1.0e300; }
    let inductance = unsafe { *values };
    let frequency = unsafe { *values.add(1) };
    let reactance = unsafe { *values.add(2) };
    if !(0..=1000).contains(&inductance) || !(0..=1000).contains(&frequency) || !(0..=1000).contains(&reactance) {
        return -1.0e300;
    }
    let zeros = (inductance == 0) as u8 + (frequency == 0) as u8 + (reactance == 0) as u8;
    if zeros != 1 { return -1.0e300; }
    let pi = 3.14159265358979323846_f64;
    if inductance == 0 { return reactance as f64 / (2.0 * pi * frequency as f64); }
    if frequency == 0 { return reactance as f64 / (2.0 * pi * inductance as f64); }
    2.0 * pi * frequency as f64 * inductance as f64
}
