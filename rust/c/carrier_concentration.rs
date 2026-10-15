/// Solve the missing semiconductor carrier concentration.
#[no_mangle]
pub extern "C" fn carrier_concentration(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length != 3 { return -1.0e300; }
    let electron_conc = unsafe { *values };
    let hole_conc = unsafe { *values.add(1) };
    let intrinsic_conc = unsafe { *values.add(2) };
    if !(0..=1_000_000).contains(&electron_conc) || !(0..=1_000_000).contains(&hole_conc) ||
        !(0..=1_000_000).contains(&intrinsic_conc) { return -1.0e300; }
    let zero_count = (electron_conc == 0) as i32 + (hole_conc == 0) as i32 + (intrinsic_conc == 0) as i32;
    if zero_count != 1 { return -1.0e300; }
    if electron_conc == 0 { return (intrinsic_conc * intrinsic_conc) as f64 / hole_conc as f64; }
    if hole_conc == 0 { return (intrinsic_conc * intrinsic_conc) as f64 / electron_conc as f64; }
    ((electron_conc * hole_conc) as f64).powf(0.5)
}
