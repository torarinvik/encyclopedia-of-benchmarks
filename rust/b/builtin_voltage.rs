/// PN junction built-in voltage over bounded integer concentrations.
#[no_mangle]
pub extern "C" fn builtin_voltage(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length != 3 { return -1.0e300; }
    let donor = unsafe { *values };
    let acceptor = unsafe { *values.add(1) };
    let intrinsic = unsafe { *values.add(2) };
    if !(1..=1000).contains(&donor) || !(1..=1000).contains(&acceptor) || !(1..=1000).contains(&intrinsic)
        || donor <= intrinsic || acceptor <= intrinsic
    { return -1.0e300; }
    let ratio = ((donor as f64) * (acceptor as f64)) / ((intrinsic as f64) * (intrinsic as f64));
    1.380649e-23_f64 * 300.0 * ratio.ln() / 1.602176634e-19_f64
}
