#[no_mangle]
pub extern "C" fn powers_of10_sequence(index: i64) -> i64 {
    if !(0..=18).contains(&index) {
        return -1;
    }
    let mut value = 1i64;
    for _ in 0..index {
        value *= 10;
    }
    value
}
