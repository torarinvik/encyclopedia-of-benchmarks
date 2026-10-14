/// Return 1 when n is a positive power of two, otherwise 0.
#[no_mangle]
pub extern "C" fn power_of_two(n: i64) -> i64 {
    (n > 0 && (n & (n - 1)) == 0) as i64
}
