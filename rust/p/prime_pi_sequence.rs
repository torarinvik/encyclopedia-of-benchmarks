const MAX_INDEX: i64 = 999;

#[no_mangle]
pub extern "C" fn prime_pi_sequence(index: i64) -> i64 {
    if index < 0 || index > MAX_INDEX {
        return -1;
    }
    let target = index + 1;
    let mut primes = [0i64; 168];
    let mut prime_count = 0usize;
    if target >= 2 {
        primes[prime_count] = 2;
        prime_count += 1;
    }
    let mut candidate = 3i64;
    while candidate <= target {
        let mut is_prime = true;
        let mut i = 0usize;
        while i < prime_count && is_prime {
            if candidate % primes[i] == 0 {
                is_prime = false;
            }
            i += 1;
        }
        if is_prime {
            primes[prime_count] = candidate;
            prime_count += 1;
        }
        candidate += 2;
    }
    prime_count as i64
}
