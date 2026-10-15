#[no_mangle]
pub extern "C" fn fermat_numbers_sequence(index: i64) -> i64 {
    if !(0..=5).contains(&index) {
        return -1;
    }
    let mut value = 2i64;
    for _ in 0..index {
        value *= value;
    }
    value + 1
}
