#[no_mangle]
pub extern "C" fn natural_sequence(index: i64) -> i64 {
    if index < 0 || index == i64::MAX {
        return -1;
    }
    index + 1
}
