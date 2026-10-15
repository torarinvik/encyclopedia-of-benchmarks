/// Photoelectric maximum electron kinetic energy in electronvolts.
#[no_mangle]
pub extern "C" fn photoelectric_effect(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length != 2 { return -1.0e300; }
    let frequency = unsafe { *values };
    let work_function = unsafe { *values.add(1) };
    if !(0..=1_000_000_000_000_000_000).contains(&frequency) || !(0..=1000).contains(&work_function) {
        return -1.0e300;
    }
    let photon_energy = 4.1357e-15_f64 * frequency as f64;
    let energy_difference = photon_energy - work_function as f64;
    if energy_difference > 0.0 { energy_difference } else { 0.0 }
}
