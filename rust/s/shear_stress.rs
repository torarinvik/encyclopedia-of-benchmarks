/// Shear stress, force, and area relation over a bounded integer-valued domain.
#[no_mangle]
pub extern "C" fn shear_stress(stress: f64, tangential_force: f64, area: f64) -> f64 {
    if !stress.is_finite() || !tangential_force.is_finite() || !area.is_finite()
        || !(0.0..=1000.0).contains(&stress)
        || !(0.0..=1000.0).contains(&tangential_force)
        || !(0.0..=1000.0).contains(&area)
        || stress != stress as i64 as f64
        || tangential_force != tangential_force as i64 as f64
        || area != area as i64 as f64
    { return -1.0; }
    let zeros = (stress == 0.0) as u8 + (tangential_force == 0.0) as u8 + (area == 0.0) as u8;
    if zeros != 1 { return -1.0; }
    if stress == 0.0 { return tangential_force / area; }
    if tangential_force == 0.0 { return stress * area; }
    tangential_force / stress
}
