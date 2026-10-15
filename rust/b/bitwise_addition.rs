/// Add nonnegative integers with XOR and shifted AND carry propagation.
#[no_mangle]
pub extern "C" fn bitwise_addition(mut first: u64, mut second: u64) -> i64 {
    while second != 0 {
        let carry = first & second;
        first ^= second;
        second = carry << 1;
    }
    first as i64
}
