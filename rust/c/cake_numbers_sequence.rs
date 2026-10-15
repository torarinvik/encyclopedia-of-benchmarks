#[no_mangle]
pub extern "C" fn cake_numbers_sequence(n: i64) -> i64 {
    if !(0..=2_000_000).contains(&n) {
        return -1;
    }
    (n * n * n + 5 * n + 6) / 6
}
