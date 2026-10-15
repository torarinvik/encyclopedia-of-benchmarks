/// Speed of sound in a fluid: (bulk modulus / density) ** 0.5.
#[no_mangle]
pub extern "C" fn speed_of_sound(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length != 2 { return -1.0e300; }
    let density = unsafe { *values };
    let bulk_modulus = unsafe { *values.add(1) };
    if !(1..=1000).contains(&density) || !(1..=1_000_000_000).contains(&bulk_modulus) {
        return -1.0e300;
    }
    ((bulk_modulus as f64) / (density as f64)).powf(0.5)
}
