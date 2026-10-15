/// Check the bounded ASCII camel-case predicate.
const MAX_LENGTH: usize = 4096;

#[no_mangle]
pub extern "C" fn check_camel_case(values: *const i64, length: usize) -> i64 {
    if length > MAX_LENGTH || (length != 0 && values.is_null()) { return -2; }
    if length == 0 { return 0; }
    for index in 0..length {
        let value = unsafe { *values.add(index) };
        if !(32..=126).contains(&value) { return -2; }
    }
    let first = unsafe { *values };
    if !(97..=122).contains(&first) { return 0; }
    for index in 0..length {
        let value = unsafe { *values.add(index) };
        if !((97..=122).contains(&value) || (65..=90).contains(&value)) { return 0; }
    }
    1
}
