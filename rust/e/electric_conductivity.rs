/// Solve one quantity in conductivity = electron concentration * mobility * charge.
#[no_mangle]
pub extern "C" fn electric_conductivity(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length != 3 { return -1.0e300; }
    let conductivity = unsafe { *values };
    let electron_conc = unsafe { *values.add(1) };
    let mobility = unsafe { *values.add(2) };
    if !(0..=1000).contains(&conductivity) || !(0..=1000).contains(&electron_conc) || !(0..=1000).contains(&mobility) {
        return -1.0e300;
    }
    let zeros = (conductivity == 0) as u8 + (electron_conc == 0) as u8 + (mobility == 0) as u8;
    if zeros != 1 { return -1.0e300; }
    const CHARGE: f64 = 1.6021e-19;
    if conductivity == 0 { return mobility as f64 * electron_conc as f64 * CHARGE; }
    if electron_conc == 0 { return conductivity as f64 / (mobility as f64 * CHARGE); }
    conductivity as f64 / (electron_conc as f64 * CHARGE)
}
