const MAX_P: i64 = 1009;
const TABLE_LEN: usize = MAX_P as usize;

fn is_prime(value: i64) -> bool {
    if value < 2 { return false; }
    let mut divisor = 2_i64;
    while divisor <= value / divisor {
        if value % divisor == 0 { return false; }
        divisor += 1;
    }
    true
}

fn pow_mod(mut base: i64, mut exponent: i64, modulus: i64) -> i64 {
    let mut result = 1_i64;
    while exponent > 0 {
        if exponent & 1 != 0 { result = result * base % modulus; }
        base = base * base % modulus;
        exponent >>= 1;
    }
    result
}

#[no_mangle]
pub unsafe extern "C" fn binomial_coefficient_lucas(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length != 3 { return -1; }
    let n = *input;
    let k = *input.add(1);
    let p = *input.add(2);
    if n < 0 || k < 0 || k > n || !(2..=MAX_P).contains(&p) || !is_prime(p) { return -1; }

    let p_usize = p as usize;
    let mut factorial = [0_i64; TABLE_LEN];
    let mut inverse_factorial = [0_i64; TABLE_LEN];
    factorial[0] = 1;
    for i in 1..p_usize {
        factorial[i] = factorial[i - 1] * i as i64 % p;
    }
    inverse_factorial[p_usize - 1] = pow_mod(factorial[p_usize - 1], p - 2, p);
    for i in (1..p_usize).rev() {
        inverse_factorial[i - 1] = inverse_factorial[i] * i as i64 % p;
    }

    let mut remaining_n = n;
    let mut remaining_k = k;
    let mut result = 1_i64;
    while remaining_n > 0 || remaining_k > 0 {
        let n_digit = (remaining_n % p) as usize;
        let k_digit = (remaining_k % p) as usize;
        if k_digit > n_digit { return 0; }
        result = result * factorial[n_digit] % p;
        result = result * inverse_factorial[k_digit] % p;
        result = result * inverse_factorial[n_digit - k_digit] % p;
        remaining_n /= p;
        remaining_k /= p;
    }
    result
}
