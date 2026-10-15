/// Solve the unknown resistance in a balanced Wheatstone bridge.
#[no_mangle]
pub extern "C" fn wheatstone_bridge(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length != 3 { return -1.0e300; }
    let resistance_1 = unsafe { *values };
    let resistance_2 = unsafe { *values.add(1) };
    let resistance_3 = unsafe { *values.add(2) };
    if !(1..=1_000_000).contains(&resistance_1) ||
       !(1..=1_000_000).contains(&resistance_2) ||
       !(1..=1_000_000).contains(&resistance_3) {
        return -1.0e300;
    }
    (resistance_2 as f64 / resistance_1 as f64) * resistance_3 as f64
}
