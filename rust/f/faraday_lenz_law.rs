#[no_mangle]
pub unsafe extern "C" fn faraday_lenz_law(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length != 3 { return i64::MIN; }
    let final_flux = *values;
    let initial_flux = *values.add(1);
    let interval = *values.add(2);
    if !(-1_000_000_000..=1_000_000_000).contains(&final_flux)
        || !(-1_000_000_000..=1_000_000_000).contains(&initial_flux)
        || !(1..=1_000_000_000).contains(&interval) { return i64::MIN; }
    let numerator = -(final_flux - initial_flux) * 10;
    let magnitude = numerator.abs();
    let mut quotient = magnitude / interval;
    let remainder = magnitude % interval;
    if 2 * remainder > interval || (2 * remainder == interval && quotient % 2 != 0) {
        quotient += 1;
    }
    if numerator < 0 { -quotient } else { quotient }
}
