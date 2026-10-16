#[no_mangle]
pub extern "C" fn nimply_gate(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length != 2 { return -1; }
    let (a, b) = unsafe { (*values, *values.add(1)) };
    if (a != 0 && a != 1) || (b != 0 && b != 1) { return -1; }
    i64::from(a == 1 && b == 0)
}
