/// Return the Möbius function for a bounded positive integer.
#[no_mangle]
pub extern "C" fn mobius_function(n: i64) -> i64 {
    if !(1..=10_000).contains(&n) {
        return i64::MIN;
    }
    let mut remaining = n;
    let mut distinct_factor_count = 0i64;
    let mut factor = 2i64;
    while factor * factor <= remaining {
        if remaining % factor == 0 {
            remaining /= factor;
            if remaining % factor == 0 {
                return 0;
            }
            distinct_factor_count += 1;
        }
        factor += 1;
    }
    if remaining > 1 {
        distinct_factor_count += 1;
    }
    if distinct_factor_count % 2 == 0 { 1 } else { -1 }
}
