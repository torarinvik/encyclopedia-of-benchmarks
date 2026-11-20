const MAX_LIMIT: i64 = 5000;
const MAX_PARSEABLE_LENGTH: usize = 2;

fn modular_power(mut base: i64, mut exponent: i64, modulus: i64) -> i64 {
    let mut result = 1i64;
    while exponent > 0 {
        if (exponent & 1) != 0 { result = (result * base) % modulus; }
        base = (base * base) % modulus;
        exponent >>= 1;
    }
    result
}

fn count_wieferich(limit: usize) -> i64 {
    let mut prime = [0u8; 5001];
    for n in 0..=limit { prime[n] = 1; }
    prime[0] = 0;
    prime[1] = 0;
    let mut divisor = 2usize;
    while divisor * divisor <= limit {
        if prime[divisor] != 0 {
            let mut multiple = divisor * divisor;
            while multiple <= limit {
                prime[multiple] = 0;
                multiple += divisor;
            }
        }
        divisor += 1;
    }
    let mut count = 0i64;
    let mut p = 3usize;
    while p <= limit {
        if prime[p] != 0 {
            let p64 = p as i64;
            if modular_power(2, p64 - 1, p64 * p64) == 1 { count += 1; }
        }
        p += 2;
    }
    count
}

#[no_mangle]
pub unsafe extern "C" fn wieferich_prime_count_up_to_limit(
    input: *const i64,
    length: usize,
) -> i64 {
    if input.is_null() || !(1..=MAX_PARSEABLE_LENGTH).contains(&length) { return -1; }
    if length != 1 { return -1; }
    let limit = *input;
    if !(2..=MAX_LIMIT).contains(&limit) { return -1; }
    count_wieferich(limit as usize)
}
