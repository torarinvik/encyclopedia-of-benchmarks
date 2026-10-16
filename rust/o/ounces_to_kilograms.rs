/// Convert ounces to kilograms with the pinned coefficient and operation order.
#[no_mangle]
pub extern "C" fn ounces_to_kilograms(ounces: f64) -> f64 {
    if ounces < -1_000_000.0 || ounces > 1_000_000.0 { return -1e300; }
    (ounces * 28.3498) / 1000.0
}
