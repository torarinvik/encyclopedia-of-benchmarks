/// Buoyant force: fluid density * gravity * displaced volume.
#[no_mangle]
pub extern "C" fn archimedes_principle_of_buoyant_force(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length != 2 { return -1.0e300; }
    let fluid_density = unsafe { *values };
    let volume = unsafe { *values.add(1) };
    if !(1..=1000).contains(&fluid_density) || !(1..=1000).contains(&volume) {
        return -1.0e300;
    }
    ((fluid_density as f64) * 9.80665) * (volume as f64)
}
