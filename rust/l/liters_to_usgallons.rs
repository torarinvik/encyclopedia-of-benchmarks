#[no_mangle]
pub extern "C" fn liters_to_usgallons(liters: f64) -> f64 {
    if !liters.is_finite() || !(-1.0e100..=1.0e100).contains(&liters) {
        return -1.0e300;
    }
    liters / 3.785411784
}
