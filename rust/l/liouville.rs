/// Go's distinct-factor Liouville variant: (-1) raised to omega(n).
#[no_mangle]
pub extern "C" fn liouville(input: i64) -> i64 {
    if !(1..=2_147_483_647).contains(&input) { return -2; }
    let mut remaining = input as u64;
    let mut sign = 1i64;
    let mut factor = 2u64;
    while factor <= remaining / factor {
        if remaining % factor == 0 {
            sign = -sign;
            while remaining % factor == 0 { remaining /= factor; }
        }
        if factor == 2 { factor = 3; } else { factor += 2; }
    }
    if remaining > 1 { sign = -sign; }
    sign
}
