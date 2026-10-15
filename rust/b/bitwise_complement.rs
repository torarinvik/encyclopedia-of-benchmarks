/// Complement only the significant binary digits of a nonnegative integer.
#[no_mangle]
pub extern "C" fn bitwise_complement(n: i64) -> i64 {
    if !(0..=i32::MAX as i64).contains(&n) {
        return -1;
    }
    if n == 0 {
        return 1;
    }
    let mut value = n as u64;
    let mut mask = 0_u64;
    while value != 0 {
        mask = (mask << 1) | 1;
        value >>= 1;
    }
    n ^ mask as i64
}
