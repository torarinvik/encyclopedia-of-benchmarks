/// Sum LCM(i, n), 1 <= i <= n, using the Euler-totient identity.
fn euler_phi(value: u64) -> u64 {
    let mut result = value;
    let mut remaining = value;
    let mut factor = 2u64;
    while factor <= remaining / factor {
        if remaining % factor == 0 {
            result -= result / factor;
            while remaining % factor == 0 { remaining /= factor; }
        }
        if factor == 2 { factor = 3; } else { factor += 2; }
    }
    if remaining > 1 { result -= result / remaining; }
    result
}

#[no_mangle]
pub extern "C" fn lcm_sum(input: i64) -> i64 {
    if !(1..=65535).contains(&input) { return -1; }
    let n = input as u64;
    let mut weighted_totients = 1u64;
    let mut divisor = 1u64;
    while divisor <= n / divisor {
        if n % divisor == 0 {
            weighted_totients += divisor * euler_phi(divisor);
            let paired = n / divisor;
            if paired != divisor { weighted_totients += paired * euler_phi(paired); }
        }
        divisor += 1;
    }
    ((weighted_totients * n) / 2) as i64
}
