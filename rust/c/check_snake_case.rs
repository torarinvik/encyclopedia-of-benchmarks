const MAX_LENGTH: usize = 4096;

#[no_mangle]
pub extern "C" fn check_snake_case(values: *const i64, length: usize) -> i64 {
    if length > MAX_LENGTH || (length != 0 && values.is_null()) { return -2; }
    let mut found = 0;
    for index in 0..length {
        let value = unsafe { *values.add(index) };
        if !(32..=126).contains(&value) { return -2; }
        if value == 95 { found = 1; }
    }
    found
}
