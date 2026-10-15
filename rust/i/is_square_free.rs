/// Return whether positive n has no repeated prime factor.
#[no_mangle]
pub extern "C" fn is_square_free(n: i64) -> i64 {
    if !(1..=1_000_000).contains(&n) {
        return -1;
    }
    let mut remaining = n;
    let mut factor = 2i64;
    while factor <= remaining / factor {
        if remaining % factor == 0 {
            remaining /= factor;
            if remaining % factor == 0 {
                return 0;
            }
        }
        factor += 1;
    }
    1
}
