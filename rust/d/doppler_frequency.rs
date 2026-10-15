/// Doppler frequency using the bounded integer-valued source contract.
#[no_mangle]
pub extern "C" fn doppler_frequency(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length != 4 { return -1.0e300; }
    let org_freq = unsafe { *values };
    let wave_vel = unsafe { *values.add(1) };
    let obs_vel = unsafe { *values.add(2) };
    let src_vel = unsafe { *values.add(3) };
    if !(1..=1000).contains(&org_freq) || !(200..=1000).contains(&wave_vel)
        || !(-100..=100).contains(&obs_vel) || !(-100..=100).contains(&src_vel)
    { return -1.0e300; }
    (org_freq as f64 * (wave_vel as f64 + obs_vel as f64)) / (wave_vel as f64 - src_vel as f64)
}
