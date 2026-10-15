#[no_mangle]
pub extern "C" fn bitwise_gcd(left: u64, right: u64) -> i64 {
    if left == 0 {
        return right as i64;
    }
    if right == 0 {
        return left as i64;
    }

    let common_twos = (left | right).trailing_zeros();
    let mut a = left >> left.trailing_zeros();
    let mut b = right;
    while b != 0 {
        b >>= b.trailing_zeros();
        if a > b {
            std::mem::swap(&mut a, &mut b);
        }
        b -= a;
    }
    (a << common_twos) as i64
}
