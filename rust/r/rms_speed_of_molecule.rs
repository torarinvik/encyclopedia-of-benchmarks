/// RMS molecular speed: (3 * R * temperature / molar_mass) ** 0.5.
#[no_mangle]
pub extern "C" fn rms_speed_of_molecule(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length != 2 { return -1.0e300; }
    let temperature = unsafe { *values };
    let molar_mass = unsafe { *values.add(1) };
    if !(0..=1000).contains(&temperature) || !(1..=1000).contains(&molar_mass) {
        return -1.0e300;
    }
    let numerator = (3.0 * 8.3144598) * (temperature as f64);
    (numerator / molar_mass as f64).powf(0.5)
}
