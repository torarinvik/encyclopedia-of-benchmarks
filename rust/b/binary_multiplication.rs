/// Multiply nonnegative operands with shift-and-add; inputs are at most 1e9.
#[no_mangle]
pub extern "C" fn binary_multiplication(mut a: u64, mut b: u64) -> i64 {
    let mut result = 0_u64;
    while b > 0 {
        if (b & 1) != 0 {
            result += a;
        }
        a += a;
        b >>= 1;
    }
    result as i64
}
