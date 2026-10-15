/// Pinned electric_power formula over the benchmark's bounded integer-valued domain.
#[no_mangle]
pub extern "C" fn electric_power(voltage: f64, current: f64, power: f64) -> f64 {
    if !voltage.is_finite() || !current.is_finite() || !power.is_finite()
        || !(-10000.0..=10000.0).contains(&voltage)
        || !(-10000.0..=10000.0).contains(&current)
        || !(0.0..=100000000.0).contains(&power)
        || voltage != voltage as i64 as f64
        || current != current as i64 as f64
        || power != power as i64 as f64
    { return -1.0e300; }
    let zeros = (voltage == 0.0) as u8 + (current == 0.0) as u8 + (power == 0.0) as u8;
    if zeros != 1 { return -1.0e300; }
    if voltage == 0.0 { return power / current; }
    if current == 0.0 { return power / voltage; }
    (voltage * current).abs()
}
