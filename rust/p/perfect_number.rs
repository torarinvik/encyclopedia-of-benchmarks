/// Check whether n equals the sum of its positive proper divisors.
#[no_mangle]
pub extern "C" fn perfect_number(n: i64) -> i64 {
    if n <= 1 {
        return 0;
    }
    if n > 1_000_000_000_000 {
        return -1;
    }

    let mut divisor_sum = 1i64;
    let mut factor = 2i64;
    while factor <= n / factor {
        if n % factor == 0 {
            divisor_sum += factor;
            let partner = n / factor;
            if partner != factor {
                divisor_sum += partner;
            }
            if divisor_sum > n {
                return 0;
            }
        }
        factor += 1;
    }
    (divisor_sum == n) as i64
}
