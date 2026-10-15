/// Solve impedance, resistance, or reactance from the other two values.
#[no_mangle]
pub extern "C" fn electrical_impedance(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length != 3 { return -1.0e300; }
    let resistance = unsafe { *values };
    let reactance = unsafe { *values.add(1) };
    let impedance = unsafe { *values.add(2) };
    if !(0..=1000).contains(&resistance) || !(0..=1000).contains(&reactance) || !(0..=1000).contains(&impedance) {
        return -1.0e300;
    }
    let zeros = (resistance == 0) as u8 + (reactance == 0) as u8 + (impedance == 0) as u8;
    if zeros != 1 { return -1.0e300; }
    let r = resistance as f64;
    let x = reactance as f64;
    let z = impedance as f64;
    let radicand = if resistance == 0 { z * z - x * x }
                   else if reactance == 0 { z * z - r * r }
                   else { r * r + x * x };
    if radicand < 0.0 { return -1.0e300; }
    radicand.sqrt()
}
