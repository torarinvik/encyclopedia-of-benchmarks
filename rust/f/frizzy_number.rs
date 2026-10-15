/// Sum base powers at the set-bit positions of n.
#[no_mangle]
pub extern "C" fn frizzy_number(base: i64, n: i64) -> i64 {
    if !(2..=10).contains(&base) || !(0..=1023).contains(&n) {
        return -1;
    }
    let mut remaining = n;
    let mut result = 0;
    let mut power = 1;
    while remaining > 0 {
        if remaining % 2 == 1 {
            result += power;
        }
        remaining /= 2;
        if remaining > 0 {
            power *= base;
        }
    }
    result
}
