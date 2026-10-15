#[no_mangle]
pub extern "C" fn matchstick_triangle_sequence(n: i64) -> i64 {
    if !(0..=1_000_000).contains(&n) {
        return -1;
    }
    (n * (n + 2) * (2 * n + 1)) / 8
}
