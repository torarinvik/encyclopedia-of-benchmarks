/// Return a term from the bounded powers-of-two sequence.
#[no_mangle]
pub extern "C" fn powers_of2_sequence(index: i64) -> i64 {
    if !(0..=62).contains(&index) {
        return -1;
    }
    let mut value = 1i64;
    for _ in 0..index {
        value *= 2;
    }
    value
}
