/// Greatest prime factor over the bounded primelib input domain.
fn is_prime_trial(value: i64) -> bool {
    if value < 2 {
        return false;
    }
    let mut divisor = 2;
    while divisor <= value / divisor {
        if value % divisor == 0 {
            return false;
        }
        divisor += 1;
    }
    true
}

#[no_mangle]
pub extern "C" fn greatest_prime_factor(n: i64) -> i64 {
    if !(0..=1_000_000).contains(&n) {
        return -1;
    }
    if n < 2 {
        return n;
    }
    if is_prime_trial(n) {
        return n;
    }

    let mut quotient = n;
    let mut largest = 0;
    let mut factor = 2;
    while quotient != 1 {
        if is_prime_trial(factor) && quotient % factor == 0 {
            largest = factor;
            quotient /= factor;
        } else {
            factor += 1;
        }
    }
    largest
}
