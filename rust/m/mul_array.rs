const MAX_INPUT_LENGTH: usize = 9;

#[no_mangle]
pub unsafe extern "C" fn mul_array(values: *const i64, length: usize) -> i64 {
    if length > MAX_INPUT_LENGTH { return -1; }
    if length == 0 { return 1; }
    if values.is_null() { return -1; }

    let mut product = 1i64;
    for index in 0..length {
        let value = *values.add(index);
        if !(0..=99).contains(&value) { return -1; }
        product *= value;
    }
    product
}
