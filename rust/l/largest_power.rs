/// Legendre's formula for the exponent of prime p in n!.
fn is_prime(value: u64) -> bool {
    if value < 2 {
        return false;
    }
    let mut divisor = 2u64;
    while divisor <= value / divisor {
        if value % divisor == 0 {
            return false;
        }
        divisor += 1;
    }
    true
}

#[no_mangle]
pub extern "C" fn largest_power(n: u64, p: u64) -> i64 {
    if n > u32::MAX as u64 || p > u16::MAX as u64 || !is_prime(p) {
        return -1;
    }
    let mut quotient = n;
    let mut total = 0i64;
    while quotient != 0 {
        quotient /= p;
        total += quotient as i64;
    }
    total
}
