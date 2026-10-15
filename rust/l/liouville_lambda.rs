/// Liouville's function: (-1) raised to the number of prime factors with multiplicity.
#[no_mangle]
pub extern "C" fn liouville_lambda(input: i64) -> i64 {
    if !(1..=2_147_483_647).contains(&input) { return -1; }
    let mut remaining = input as u64;
    let mut sign = 1i64;
    let mut factor = 2u64;
    while factor <= remaining / factor {
        while remaining % factor == 0 {
            remaining /= factor;
            sign = -sign;
        }
        if factor == 2 { factor = 3; } else { factor += 2; }
    }
    if remaining > 1 { sign = -sign; }
    sign
}
