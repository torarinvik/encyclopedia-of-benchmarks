/// Bounded port of TheAlgorithms/Python Project Euler 38 search.
fn is_9_pandigital(mut value: i64) -> bool {
    if !(100_000_000..=999_999_999).contains(&value) {
        return false;
    }
    let mut mask = 0u16;
    while value > 0 {
        let digit = (value % 10) as u16;
        if digit == 0 || mask & (1u16 << digit) != 0 {
            return false;
        }
        mask |= 1u16 << digit;
        value /= 10;
    }
    mask == 0x3fe
}

#[no_mangle]
pub extern "C" fn problem38(unused: i64) -> i64 {
    if unused != 0 {
        return -1;
    }
    for base in (5000..=9999).rev() {
        let candidate = 100_002 * base;
        if is_9_pandigital(candidate) {
            return candidate;
        }
    }
    for base in (100..=333).rev() {
        let candidate = 1_002_003 * base;
        if is_9_pandigital(candidate) {
            return candidate;
        }
    }
    -1
}
