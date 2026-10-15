/// Pressure from the ideal gas law: n * T * R / V.
#[no_mangle]
pub extern "C" fn ideal_gas_law(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length != 3 { return -1.0e300; }
    let moles = unsafe { *values };
    let kelvin = unsafe { *values.add(1) };
    let volume = unsafe { *values.add(2) };
    if !(0..=1000).contains(&moles) || !(0..=1000).contains(&kelvin) || !(1..=1000).contains(&volume) {
        return -1.0e300;
    }
    ((moles as f64) * (kelvin as f64) * 8.314462) / (volume as f64)
}
