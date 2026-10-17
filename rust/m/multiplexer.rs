#[no_mangle]
pub unsafe extern "C" fn multiplexer(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length != 3 { return -1; }
    let input0 = *values;
    let input1 = *values.add(1);
    let select = *values.add(2);
    if (input0 != 0 && input0 != 1) || (input1 != 0 && input1 != 1) ||
        (select != 0 && select != 1) { return -1; }
    if select == 1 { input1 } else { input0 }
}
