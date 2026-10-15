/// Solve one missing quantity in the ideal-plate Casimir force equation.
#[no_mangle]
pub extern "C" fn casimir_effect(values: *const i64, length: usize) -> f64 {
    const HBAR: f64 = 1.054571817e-34;
    const SPEED_OF_LIGHT: f64 = 3.0e8;
    const PI_VALUE: f64 = 3.14159265358979323846;
    if values.is_null() || length != 3 { return -1.0e300; }
    let force_units = unsafe { *values };
    let area_units = unsafe { *values.add(1) };
    let distance_units = unsafe { *values.add(2) };
    if !(0..=1_000_000).contains(&force_units) || !(0..=1_000_000).contains(&area_units) ||
        !(0..=1_000_000).contains(&distance_units) { return -1.0e300; }
    let zero_count = (force_units == 0) as i32 + (area_units == 0) as i32 + (distance_units == 0) as i32;
    if zero_count != 1 { return -1.0e300; }
    let force = force_units as f64 * 1.0e-12;
    let area = area_units as f64 * 1.0e-6;
    let distance = distance_units as f64 * 1.0e-6;
    if force_units == 0 {
        return (HBAR * SPEED_OF_LIGHT * PI_VALUE.powf(2.0) * area) / (240.0 * distance.powf(4.0));
    }
    if area_units == 0 {
        return (240.0 * force * distance.powf(4.0)) / (HBAR * SPEED_OF_LIGHT * PI_VALUE.powf(2.0));
    }
    ((HBAR * SPEED_OF_LIGHT * PI_VALUE.powf(2.0) * area) / (240.0 * force)).powf(0.25)
}
