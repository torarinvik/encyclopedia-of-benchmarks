/// Three reciprocal thin-lens formula solves.
#[no_mangle]
pub extern "C" fn lens_formulae(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length != 3 { return -1.0e300; }
    let operation = unsafe { *values };
    let first = unsafe { *values.add(1) };
    let second = unsafe { *values.add(2) };
    if !(0..=2).contains(&operation) || first == 0 || second == 0 ||
        !(-1_000_000..=1_000_000).contains(&first) || !(-1_000_000..=1_000_000).contains(&second) {
        return -1.0e300;
    }
    if operation == 0 {
        if first == second { return -1.0e300; }
        return 1.0 / ((1.0 / second as f64) - (1.0 / first as f64));
    }
    if operation == 1 {
        if first == second { return -1.0e300; }
        return 1.0 / ((1.0 / second as f64) - (1.0 / first as f64));
    }
    if first == -second { return -1.0e300; }
    1.0 / ((1.0 / second as f64) + (1.0 / first as f64))
}
