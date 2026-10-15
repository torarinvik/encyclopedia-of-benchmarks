/// Estimate altitude from pressure using the pinned source formula.
#[no_mangle]
pub extern "C" fn altitude_pressure(pressure: f64) -> f64 {
    if pressure < 0.0 || pressure > 101325.0 { return -1.0; }
    if pressure == 0.0 { return 44330.0; }
    let exponent = 1.0 / 5.5255;
    44330.0 * (1.0 - (pressure / 101325.0).powf(exponent))
}
