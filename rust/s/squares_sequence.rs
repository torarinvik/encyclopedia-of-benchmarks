const MAX_INDEX: i64 = 3_037_000_499;

#[no_mangle]
pub extern "C" fn squares_sequence(index: i64) -> i64 {
    if index < 0 || index > MAX_INDEX {
        return -1;
    }
    index * index
}
