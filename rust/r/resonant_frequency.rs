/// LC resonant frequency over bounded integer-valued inputs.
#[no_mangle]
pub extern "C" fn resonant_frequency(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length != 2 { return -1.0e300; }
    let inductance = unsafe { *values };
    let capacitance = unsafe { *values.add(1) };
    if !(1..=1000).contains(&inductance) || !(1..=1000).contains(&capacitance) { return -1.0e300; }
    let pi = 3.14159265358979323846_f64;
    1.0 / (2.0 * pi * ((inductance as f64) * (capacitance as f64)).sqrt())
}
