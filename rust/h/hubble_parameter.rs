const INVALID_RESULT: f64 = -1.0e300;

#[no_mangle]
pub extern "C" fn hubble_parameter(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length != 5 { return INVALID_RESULT; }
    let h0_x10 = unsafe { *values };
    let radiation_ppm = unsafe { *values.add(1) };
    let matter_ppm = unsafe { *values.add(2) };
    let dark_energy_ppm = unsafe { *values.add(3) };
    let redshift_milli = unsafe { *values.add(4) };
    if !(-2000..=2000).contains(&h0_x10) || !(0..=1_000_000).contains(&radiation_ppm) ||
        !(0..=1_000_000).contains(&matter_ppm) || !(0..=1_000_000).contains(&dark_energy_ppm) ||
        radiation_ppm + matter_ppm + dark_energy_ppm > 1_000_000 || !(0..=10_000).contains(&redshift_milli) { return INVALID_RESULT; }
    let hubble_constant = h0_x10 as f64 / 10.0;
    let radiation_density = radiation_ppm as f64 / 1_000_000.0;
    let matter_density = matter_ppm as f64 / 1_000_000.0;
    let dark_energy = dark_energy_ppm as f64 / 1_000_000.0;
    let redshift = redshift_milli as f64 / 1_000.0;
    let curvature = 1.0 - (matter_density + radiation_density + dark_energy);
    let z1 = redshift + 1.0;
    let e2 = radiation_density * z1.powf(4.0) + matter_density * z1.powf(3.0) + curvature * z1.powf(2.0) + dark_energy;
    hubble_constant * e2.powf(1.0 / 2.0)
}
