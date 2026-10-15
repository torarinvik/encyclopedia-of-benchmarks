/// Ohm's law over a bounded integer-valued input domain.
#[no_mangle]
pub extern "C" fn ohms_law(voltage: f64, current: f64, resistance: f64) -> f64 {
    if !voltage.is_finite() || !current.is_finite() || !resistance.is_finite()
        || !(-1000.0..=1000.0).contains(&voltage)
        || !(-1000.0..=1000.0).contains(&current)
        || !(0.0..=1000.0).contains(&resistance)
        || voltage.fract() != 0.0 || current.fract() != 0.0 || resistance.fract() != 0.0
    { return -1e300; }
    let zeros = (voltage == 0.0) as u8 + (current == 0.0) as u8 + (resistance == 0.0) as u8;
    if zeros != 1 { return -1e300; }
    if voltage == 0.0 { return current * resistance; }
    if current == 0.0 { return voltage / resistance; }
    voltage / current
}
