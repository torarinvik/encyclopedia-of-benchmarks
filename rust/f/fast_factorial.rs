/// Prime-exponent factorial using binary buckets and balanced powers.
const MAX_N: i64 = 20;
const MAX_BUCKETS: usize = 8;

fn exponent_in_factorial(prime: i64, n: i64) -> i64 {
    let mut exponent = 0;
    let mut quotient = n / prime;
    while quotient > 0 {
        exponent += quotient;
        quotient /= prime;
    }
    exponent
}

fn power_by_squaring(base: i64, exponent: u32) -> i64 {
    let mut result = 1;
    let mut factor = base;
    let mut remaining = exponent;
    while remaining > 0 {
        if remaining & 1 != 0 { result *= factor; }
        remaining >>= 1;
        if remaining > 0 { factor *= factor; }
    }
    result
}

#[no_mangle]
pub extern "C" fn fast_factorial(n: i64) -> i64 {
    if !(0..=MAX_N).contains(&n) { return -1; }
    if n < 2 { return 1; }

    let mut is_prime = [false; MAX_N as usize + 1];
    for candidate in 2..=n as usize { is_prime[candidate] = true; }
    let mut prime = 2usize;
    while prime * prime <= n as usize {
        if is_prime[prime] {
            let mut multiple = prime * prime;
            while multiple <= n as usize {
                is_prime[multiple] = false;
                multiple += prime;
            }
        }
        prime += 1;
    }

    let exponent_of_two = exponent_in_factorial(2, n);
    let mut next_power_of_two = 1i64;
    let mut power_log2 = 0u32;
    while next_power_of_two < exponent_of_two {
        next_power_of_two <<= 1;
        power_log2 += 1;
    }
    let bucket_count = (power_log2 + 1) as usize;
    let mut buckets = [1i64; MAX_BUCKETS];

    for candidate in 2..=n as usize {
        if !is_prime[candidate] { continue; }
        let exponent_bits = exponent_in_factorial(candidate as i64, n) as u32;
        for bit in 0..bucket_count {
            if exponent_bits & (1u32 << bit) != 0 { buckets[bit] *= candidate as i64; }
        }
    }

    let mut result = 1i64;
    for bit in 0..bucket_count {
        result *= power_by_squaring(buckets[bit], 1u32 << bit);
    }
    result
}
