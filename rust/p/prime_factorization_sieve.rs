/// Sieve through n, then emit ascending prime/exponent pairs as little-endian u32 values.
#[no_mangle]
pub unsafe extern "C" fn prime_factorization_sieve(
    value: i64,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if !(1..=1_000_005).contains(&value) { return -1; }
    if value == 1 { return 0; }

    let limit = value as usize;
    let mut is_prime = vec![true; limit + 1];
    is_prime[0] = false;
    is_prime[1] = false;
    let mut prime = 2usize;
    while prime <= limit / prime {
        if is_prime[prime] {
            let mut multiple = prime * prime;
            while multiple <= limit {
                is_prime[multiple] = false;
                multiple += prime;
            }
        }
        prime += 1;
    }

    let mut primes = [0u32; 10];
    let mut exponents = [0u32; 10];
    let mut count = 0usize;
    let mut remaining = value;
    for prime in 2..=limit {
        if remaining == 1 { break; }
        if !is_prime[prime] { continue; }
        let mut exponent = 0u32;
        while remaining % prime as i64 == 0 {
            remaining /= prime as i64;
            exponent += 1;
        }
        if exponent != 0 {
            primes[count] = prime as u32;
            exponents[count] = exponent;
            count += 1;
        }
    }
    let required = count * 8;
    if output.is_null() || output_capacity < required { return -2; }
    for index in 0..count {
        let encoded = [
            primes[index].to_le_bytes(),
            exponents[index].to_le_bytes(),
        ];
        for (word, bytes) in encoded.iter().enumerate() {
            for (byte, value) in bytes.iter().enumerate() {
                output.add(8 * index + 4 * word + byte).write(*value);
            }
        }
    }
    required as i64
}
