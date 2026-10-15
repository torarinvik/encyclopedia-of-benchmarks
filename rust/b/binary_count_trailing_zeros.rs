/// Count low-order zero bits by shifting away factors of two.
#[no_mangle]
pub extern "C" fn binary_count_trailing_zeros(mut n: i64) -> i64 {
    if n < 0 { return -1; }
    let mut count = 0;
    while n > 0 && (n & 1) == 0 {
        n >>= 1;
        count += 1;
    }
    count
}
