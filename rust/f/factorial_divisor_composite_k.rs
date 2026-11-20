fn factorial_divisor_composite_k_valuation(mut n: u64, prime: u64) -> u64 {
    let mut total = 0;
    while n != 0 {
        n /= prime;
        total += n;
    }
    total
}

#[no_mangle]
pub extern "C" fn factorial_divisor_composite_k(n: u64, k: u64) -> i64 {
    if n > 1_000_000_000_000 || !(4..=1_000_000).contains(&k) {
        return -1;
    }

    let mut remaining = k;
    let mut divisor = 2;
    let mut answer = n;
    let mut composite = false;
    while divisor <= remaining / divisor {
        if remaining % divisor == 0 {
            composite = true;
            let mut exponent = 0;
            while remaining % divisor == 0 {
                remaining /= divisor;
                exponent += 1;
            }
            let candidate = factorial_divisor_composite_k_valuation(n, divisor) / exponent;
            answer = answer.min(candidate);
        }
        divisor += 1;
    }

    if !composite {
        return -1;
    }
    if remaining > 1 {
        let candidate = factorial_divisor_composite_k_valuation(n, remaining);
        answer = answer.min(candidate);
    }
    answer as i64
}
