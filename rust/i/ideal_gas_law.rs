/// Solve one ideal-gas-law variable using a portable operation selector.
#[no_mangle]
pub extern "C" fn ideal_gas_law(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length != 4 { return -1.0e300; }
    let operation = unsafe { *values };
    let a = unsafe { *values.add(1) };
    let b = unsafe { *values.add(2) };
    let c = unsafe { *values.add(3) };
    if !(0..=3).contains(&operation) || !(0..=1000).contains(&a) || !(0..=1000).contains(&b) || !(0..=1000).contains(&c) {
        return -1.0e300;
    }
    if operation == 0 || operation == 1 {
        if c == 0 { return -1.0e300; }
        return ((a as f64) * (b as f64) * 8.314462) / (c as f64);
    }
    if a == 0 { return -1.0e300; }
    ((c as f64) * (b as f64)) / ((a as f64) * 8.314462)
}
