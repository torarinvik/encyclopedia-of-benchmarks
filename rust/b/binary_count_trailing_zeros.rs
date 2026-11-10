/// Count low-order zero bits.
#[no_mangle]
pub extern "C" fn binary_count_trailing_zeros(n: i64) -> i64 {
    if n <= 0 { return if n < 0 { -1 } else { 0 }; }
    i64::from(n.trailing_zeros())
}
