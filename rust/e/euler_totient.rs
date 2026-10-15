/// Euler's totient via distinct-prime factorization.
#[no_mangle]
pub extern "C" fn euler_totient(n: i64) -> i64 {
    if !(1..=1_000_000).contains(&n) { return -1; }
    let mut result = n;
    let mut remaining = n;
    let mut factor = 2i64;
    while factor <= remaining / factor {
        if remaining % factor == 0 {
            while remaining % factor == 0 { remaining /= factor; }
            result -= result / factor;
        }
        factor += 1;
    }
    if remaining > 1 { result -= result / remaining; }
    result
}
