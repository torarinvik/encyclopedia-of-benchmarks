/// Real/reactive power from apparent power and power factor.
#[no_mangle]
pub extern "C" fn real_and_reactive_power(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length != 3 { return -1.0e300; }
    let operation = unsafe { *values };
    let apparent_power = unsafe { *values.add(1) };
    let factor_units = unsafe { *values.add(2) };
    if (operation != 0 && operation != 1) || !(-1_000_000_000..=1_000_000_000).contains(&apparent_power) ||
        !(-10_000..=10_000).contains(&factor_units) {
        return -1.0e300;
    }
    let power_factor = factor_units as f64 / 10_000.0;
    if operation == 0 { return apparent_power as f64 * power_factor; }
    apparent_power as f64 * (1.0 - power_factor.powf(2.0)).sqrt()
}
