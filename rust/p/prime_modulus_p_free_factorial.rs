const MAX_PRIME: i64 = 1009;
const FACTORIAL_CAPACITY: usize = 1009;

fn is_prime(value: i64) -> bool {
    if value < 2 {
        return false;
    }
    let mut divisor = 2i64;
    while divisor <= value / divisor {
        if value % divisor == 0 {
            return false;
        }
        divisor += 1;
    }
    true
}

#[no_mangle]
pub unsafe extern "C" fn prime_modulus_p_free_factorial(
    input: *const i64,
    length: usize,
) -> i64 {
    if input.is_null() || length != 2 {
        return -1;
    }
    let n = *input;
    let prime = *input.add(1);
    if n < 0 || !(2..=MAX_PRIME).contains(&prime) || !is_prime(prime) {
        return -1;
    }

    let mut factorial = [0i64; FACTORIAL_CAPACITY];
    factorial[0] = 1;
    for value in 1..prime as usize {
        factorial[value] = factorial[value - 1] * value as i64 % prime;
    }

    let mut result = 1i64;
    let mut remaining = n;
    while remaining > 0 {
        let quotient = remaining / prime;
        let residue = (remaining % prime) as usize;
        let mut block = factorial[residue];
        if quotient & 1 != 0 {
            block = prime - block;
        }
        result = result * block % prime;
        remaining = quotient;
    }
    result
}
