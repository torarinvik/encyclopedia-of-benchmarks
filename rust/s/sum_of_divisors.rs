/// Return the sum of all positive divisors of n by prime factorization.
#[no_mangle]
pub extern "C" fn sum_of_divisors(n: i64) -> i64 {
    if !(1..=1_000_000).contains(&n) { return -1; }
    let mut remaining = n;
    let mut sigma = 1i64;
    let mut factor = 2i64;
    while factor <= remaining / factor {
        if remaining % factor == 0 {
            let mut power = 1i64;
            let mut geometric_sum = 1i64;
            while remaining % factor == 0 {
                remaining /= factor;
                power *= factor;
                geometric_sum += power;
            }
            sigma *= geometric_sum;
        }
        factor += 1;
    }
    if remaining > 1 { sigma *= remaining + 1; }
    sigma
}
