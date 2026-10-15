#[no_mangle]
pub extern "C" fn number_of_boolean_functions_sequence(index: i64) -> i64 {
    if !(0..=5).contains(&index) {
        return -1;
    }
    let mut value = 2i64;
    for _ in 0..index {
        value *= value;
    }
    value
}
